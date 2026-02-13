from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.shortcuts import get_object_or_404
from rest_framework import filters, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
from rest_framework import generics

from .models import Follower
from .serializers import RegisterSerializer, UserSerializer, ChangePasswordSerializer, FollowerSerializer

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
	queryset = User.objects.all().order_by('-date_joined')
	serializer_class = UserSerializer
	permission_classes = [permissions.IsAuthenticated]
	filter_backends = [filters.SearchFilter, filters.OrderingFilter]
	search_fields = ['username', 'email', 'phone']
	ordering_fields = ['date_joined', 'username']

	def get_permissions(self):
		if self.action in ['create']:
			return [permissions.AllowAny()]
		if self.action in ['update', 'partial_update', 'destroy']:
			return [permissions.IsAuthenticated(), IsSelfOrAdmin()]
		return super().get_permissions()


class RegisterView(APIView):
	permission_classes = [permissions.AllowAny]

	def post(self, request, *args, **kwargs):
		serializer = RegisterSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)
		user = serializer.save()
		refresh = RefreshToken.for_user(user)
		return Response(
			{
				'user': UserSerializer(user, context={'request': request}).data,
				'refresh': str(refresh),
				'access': str(refresh.access_token),
			},
			status=status.HTTP_201_CREATED,
		)


class IsSelfOrAdmin(permissions.BasePermission):
	def has_object_permission(self, request, view, obj):
		return request.user.is_superuser or obj == request.user


class MeView(APIView):
	"""Get or update current authenticated user's profile"""
	permission_classes = [permissions.IsAuthenticated]

	def get(self, request):
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
    queryset = User.objects.all()
    serializer_class = UserSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'username', 'store_description']


class UserDetailView(generics.RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer


class FollowerListView(generics.ListAPIView):
    serializer_class = FollowerSerializer
    
    def get_queryset(self):
        return Follower.objects.filter(user=self.request.user)


class FollowerToggleView(generics.CreateAPIView):
    serializer_class = FollowerSerializer
    
    def post(self, request):
        followed_user_id = request.data.get('store')  # Keep 'store' for API compatibility
        followed_user = get_object_or_404(User, id=followed_user_id)
        
        follower, created = Follower.objects.get_or_create(
            user=request.user,
            followed_user=followed_user
        )
        
        if not created:
            follower.delete()
            return Response({'is_following': False})
        
        return Response({'is_following': True})
