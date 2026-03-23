from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.conf import settings
from django.core.exceptions import ValidationError
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from rest_framework import filters, permissions, status, viewsets, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
from rest_framework import generics

from .models import Follower, StoreReport
from .models import PhoneOTP, SystemSettings, TrustSettings
from .abuse import record_abuse_signal
from .trust_scoring import high_risk_snapshot, score_store_report
from .serializers import (
	RegisterSerializer,
	UserSerializer,
	ChangePasswordSerializer,
	FollowerSerializer,
	SendPhoneOTPSerializer,
	VerifyPhoneOTPSerializer,
	PreferredCategoriesSerializer,
	StoreReportSerializer,
)
from .services import generate_otp_code, send_otp_message, generate_unique_username_from_name

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
	"""Allow login with either username or email"""
	
	def validate(self, attrs):
		username_or_email = attrs.get('username', '')
		password = attrs.get('password', '')
		
		# Try to find user by email first
		user = None
		if '@' in username_or_email:
			try:
				user = User.objects.get(email=username_or_email)
				attrs['username'] = user.username
			except User.DoesNotExist:
				pass
		
		return super().validate(attrs)


class CustomTokenObtainPairView(TokenObtainPairView):
	serializer_class = CustomTokenObtainPairSerializer


class UserViewSet(viewsets.ModelViewSet):
	serializer_class = UserSerializer
	permission_classes = [permissions.IsAuthenticatedOrReadOnly]
	filter_backends = [filters.SearchFilter, filters.OrderingFilter]
	search_fields = ['name', 'username', 'store_description', 'email', 'phone']
	ordering_fields = ['date_joined', 'username']

	def get_queryset(self):
		queryset = User.objects.all().order_by('-date_joined')
		has_posts = self.request.query_params.get('has_posts')
		if has_posts and has_posts.lower() == 'true':
			queryset = queryset.filter(products__available_status='available').distinct()
		return queryset

	def get_permissions(self):
		if self.action in ['create']:
			return [permissions.AllowAny()]
		if self.action in ['list', 'retrieve']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsSelfOrAdmin()]
		return super().get_permissions()


class RegisterView(APIView):
	permission_classes = [permissions.AllowAny]

	def post(self, request, *args, **kwargs):
		serializer = RegisterSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		from .models import SystemSettings
		settings_obj = SystemSettings.get_settings()
		user = serializer.save()
		user.coins_balance = settings_obj.first_login_coins
		user.save(update_fields=['coins_balance'])
		refresh = RefreshToken.for_user(user)
		return Response(
			{
				'user': UserSerializer(user, context={'request': request}).data,
				'refresh': str(refresh),
				'access': str(refresh.access_token),
			},
			status=status.HTTP_201_CREATED,
		)


class SendPhoneOTPView(APIView):
	permission_classes = [permissions.AllowAny]
	throttle_classes = [ScopedRateThrottle]
	throttle_scope = 'otp_send'

	def post(self, request, *args, **kwargs):
		serializer = SendPhoneOTPSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		phone = serializer.validated_data['phone']

		latest = PhoneOTP.objects.filter(phone=phone).first()
		if latest and (timezone.now() - latest.created_at).total_seconds() < 60:
			remaining = max(1, int(60 - (timezone.now() - latest.created_at).total_seconds()))
			return Response(
				{'detail': f'انتظر {remaining} ثانية قبل طلب رمز جديد'},
				status=status.HTTP_429_TOO_MANY_REQUESTS,
			)

		code = generate_otp_code()
		print(f"[OTP DEBUG] phone={phone} code={code}")
		otp = PhoneOTP.objects.create(
			phone=phone,
			code=code,
			expires_at=PhoneOTP.expiry_time(),
		)
		try:
			send_otp_message(phone, code)
		except Exception as exc:
			otp.delete()
			return Response(
				{'detail': f'فشل إرسال رمز التحقق: {exc}'},
				status=status.HTTP_400_BAD_REQUEST,
			)

		payload = {'detail': 'تم إرسال رمز التحقق بنجاح'}
		if settings.DEBUG:
			payload['otp_code'] = code
		return Response(payload, status=status.HTTP_200_OK)


class VerifyPhoneOTPView(APIView):
	permission_classes = [permissions.AllowAny]
	throttle_classes = [ScopedRateThrottle]
	throttle_scope = 'otp_verify'

	def post(self, request, *args, **kwargs):
		serializer = VerifyPhoneOTPSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		phone = serializer.validated_data['phone']
		code = serializer.validated_data['code']
		display_name = serializer.validated_data.get('name', '').strip()

		otp = PhoneOTP.objects.filter(phone=phone, is_verified=False).first()
		if not otp:
			return Response(
				{'detail': 'لا يوجد رمز تحقق لهذا الرقم'},
				status=status.HTTP_400_BAD_REQUEST,
			)
		if otp.is_expired:
			return Response(
				{'detail': 'انتهت صلاحية رمز التحقق'},
				status=status.HTTP_400_BAD_REQUEST,
			)
		if otp.attempts >= 5:
			return Response(
				{'detail': 'تم تجاوز عدد محاولات التحقق'},
				status=status.HTTP_400_BAD_REQUEST,
			)
		if otp.code != code:
			otp.attempts += 1
			otp.save(update_fields=['attempts'])
			return Response(
				{'detail': 'رمز التحقق غير صحيح'},
				status=status.HTTP_400_BAD_REQUEST,
			)

		otp.is_verified = True
		otp.save(update_fields=['is_verified'])

		user = User.objects.filter(phone=phone).first()
		is_new_user = False
		if user is None:
			is_new_user = True
			username = generate_unique_username_from_name(display_name or phone)
			user = User.objects.create(
				username=username,
				name=display_name or username,
				phone=phone,
				email='',
				coins_balance=SystemSettings.get_settings().first_login_coins,
			)
		elif display_name and not (user.name or '').strip():
			user.name = display_name
			user.save(update_fields=['name'])

		refresh = RefreshToken.for_user(user)
		return Response(
			{
				'user': UserSerializer(user, context={'request': request}).data,
				'refresh': str(refresh),
				'access': str(refresh.access_token),
				'is_new_user': is_new_user,
			},
			status=status.HTTP_200_OK,
		)


class PreferredCategoriesView(APIView):
	permission_classes = [permissions.IsAuthenticated]

	def post(self, request, *args, **kwargs):
		serializer = PreferredCategoriesSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		category_ids = serializer.validated_data['preferred_categories']

		from analytics.models import UserInterestProfile
		profile, _ = UserInterestProfile.objects.get_or_create(user=request.user)
		profile.category_scores = {str(cat_id): 50 for cat_id in category_ids}
		profile.save(update_fields=['category_scores', 'last_updated'])

		return Response({'detail': 'تم حفظ الاهتمامات بنجاح'}, status=status.HTTP_200_OK)


class IsSelfOrAdmin(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		return request.user.is_superuser or obj == request.user


class IsSelfOrAdminOrReadOnly(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		if request.method in permissions.SAFE_METHODS:
			return True
		return request.user.is_superuser or obj == request.user


class MeView(APIView):
	"""Get or update current authenticated user's profile"""
	permission_classes = [permissions.IsAuthenticated]

	def get(self, request):
		from .services import check_and_grant_daily_coins
		check_and_grant_daily_coins(request.user)
		request.user.refresh_from_db()
		serializer = UserSerializer(request.user, context={'request': request})
		return Response(serializer.data)

	def put(self, request):
		serializer = UserSerializer(request.user, data=request.data, context={'request': request})
		if serializer.is_valid():
			serializer.save()
			return Response(serializer.data)
		return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

	def patch(self, request):
		serializer = UserSerializer(request.user, data=request.data, partial=True, context={'request': request})
		if serializer.is_valid():
			serializer.save()
			return Response(serializer.data)
		return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
	"""Change password for authenticated user"""
	permission_classes = [permissions.IsAuthenticated]

	def post(self, request):
		serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
		if serializer.is_valid():
			user = request.user
			# Check old password
			if not user.check_password(serializer.validated_data['old_password']):
				return Response(
					{'old_password': ['كلمة المرور الحالية غير صحيحة']},
					status=status.HTTP_400_BAD_REQUEST
				)
			# Validate new password
			try:
				validate_password(serializer.validated_data['new_password'], user)
			except ValidationError as e:
				return Response(
					{'new_password': list(e.messages)},
					status=status.HTTP_400_BAD_REQUEST
				)
			# Set new password
			user.set_password(serializer.validated_data['new_password'])
			user.save()
			return Response({'message': 'تم تغيير كلمة المرور بنجاح'})
		return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
	"""Logout and blacklist refresh token"""
	permission_classes = [permissions.IsAuthenticated]

	def post(self, request):
		try:
			refresh_token = request.data.get('refresh')
			if refresh_token:
				token = RefreshToken(refresh_token)
				token.blacklist()
			return Response({'message': 'تم تسجيل الخروج بنجاح'}, status=status.HTTP_200_OK)
		except Exception as e:
			return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class UserListView(generics.ListAPIView):
	serializer_class = UserSerializer
	permission_classes = [permissions.IsAuthenticatedOrReadOnly]
	filter_backends = [filters.SearchFilter]
	search_fields = ['name', 'username', 'store_description']

	def get_queryset(self):
		queryset = User.objects.all()
		has_posts = self.request.query_params.get('has_posts')
		if has_posts and has_posts.lower() == 'true':
			queryset = queryset.filter(products__available_status='available').distinct()
		return queryset


class UserDetailView(generics.RetrieveUpdateAPIView):
	queryset = User.objects.all()
	serializer_class = UserSerializer
	permission_classes = [IsSelfOrAdminOrReadOnly]


class FollowerListView(generics.ListAPIView):
	serializer_class = FollowerSerializer

	def get_queryset(self):
		return Follower.objects.filter(user=self.request.user)


class FollowerToggleView(generics.CreateAPIView):
	serializer_class = FollowerSerializer

	def post(self, request):
		followed_user_id = request.data.get('store')  # Keep 'store' for API compatibility
		followed_user = get_object_or_404(User, id=followed_user_id)

		if followed_user == request.user:
			return Response({'error': 'Cannot follow yourself'}, status=status.HTTP_400_BAD_REQUEST)

		follower, created = Follower.objects.get_or_create(
			user=request.user,
			followed_user=followed_user,
		)

		if not created:
			follower.delete()
			return Response({'is_following': False})

		try:
			from analytics.utils import log_user_event
			log_user_event(
				request.user,
				'follow_store',
				metadata={
					'product_id': request.data.get('product_id') or request.data.get('product'),
					'store_id': followed_user.id,
					'category_id': request.data.get('category_id'),
					'discovery_mode': request.data.get('discovery_mode'),
					'wilaya_code': request.data.get('wilaya_code'),
					'distance_km': request.data.get('distance_km'),
					'search_query': str(request.data.get('search_query') or '').strip().lower(),
				},
				session_id=str(request.data.get('session_id') or ''),
			)
		except Exception:
			pass

		return Response({'is_following': True})


class StoreReportViewSet(viewsets.ModelViewSet):
	serializer_class = StoreReportSerializer
	permission_classes = [permissions.IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]

	def get_throttles(self):
		if self.action == 'create':
			self.throttle_scope = 'report_create'
			return [ScopedRateThrottle()]
		return super().get_throttles()

	def get_queryset(self):
		user = self.request.user
		if user.is_superuser or user.is_staff:
			return StoreReport.objects.select_related('reporter', 'store').all()
		return StoreReport.objects.select_related('reporter', 'store').filter(reporter=user)

	def perform_create(self, serializer):
		store = serializer.validated_data.get('store')
		trust = TrustSettings.get_settings()
		cutoff = timezone.now() - timedelta(minutes=int(trust.report_cooldown_minutes or 10))
		if StoreReport.objects.filter(reporter=self.request.user, store=store, created_at__gte=cutoff).exists():
			record_abuse_signal(
				actor=self.request.user,
				signal_type='report_spam',
				target_type='store',
				target_id=store.id,
				metadata={'reason': 'cooldown_hit'},
			)
			raise serializers.ValidationError({'detail': 'Please wait before submitting another report for this store.'})

		reports_today = StoreReport.objects.filter(
			reporter=self.request.user,
			created_at__date=timezone.now().date(),
		).count()
		if reports_today >= int(trust.max_reports_per_day or 20):
			record_abuse_signal(
				actor=self.request.user,
				signal_type='report_spam',
				target_type='account',
				target_id=self.request.user.id,
				metadata={'reason': 'daily_cap_hit', 'reports_today': reports_today},
			)
			raise serializers.ValidationError({'detail': 'Daily report limit reached. Try again tomorrow.'})

		scored = score_store_report(self.request.user, store)
		if scored.is_low_credibility:
			record_abuse_signal(
				actor=self.request.user,
				signal_type='low_cred_report',
				target_type='store',
				target_id=store.id,
				metadata={'score': scored.score},
			)
		serializer.save(
			reporter=self.request.user,
			seriousness_score=scored.score,
			seriousness_level=scored.level,
			evidence_snapshot=scored.evidence_snapshot,
			is_low_credibility=scored.is_low_credibility,
			reporter_reputation_score_at_submission=scored.reporter_reputation,
			scored_at=timezone.now(),
		)


class TrustModerationSnapshotView(APIView):
	permission_classes = [permissions.IsAdminUser]

	def get(self, request, *args, **kwargs):
		limit = request.query_params.get('limit')
		try:
			limit_value = max(1, min(100, int(limit or 20)))
		except Exception:
			limit_value = 20
		return Response(high_risk_snapshot(limit=limit_value), status=status.HTTP_200_OK)
