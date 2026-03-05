from django.contrib.auth import get_user_model
from rest_framework import serializers
import uuid
from django.utils import timezone
from django.db.models import Avg
from .models import Follower, StoreReport
from .services import normalize_phone

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    followers_count = serializers.SerializerMethodField()
    average_rating = serializers.SerializerMethodField()
    product_count = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    categories = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'name', 'email', 'phone', 'profile_image', 
            'gender', 'birthday',
            'store_description', 'address', 'latitude', 'longitude',
            'allow_nearby_visibility',
            'location_updated_at',
            'store_type', 'cover_image', 'followers_count', 'average_rating', 
            'facebook', 'instagram', 'whatsapp', 'tiktok', 'youtube',
            'show_phone_public', 'show_social_public',
            'product_count', 'review_count', 'categories',
            'date_joined'
        ]
        read_only_fields = ['id', 'date_joined', 'followers_count', 'average_rating', 'location_updated_at',
                            'product_count', 'review_count', 'categories']

    def validate(self, attrs):
        """Enforce 60-day coordinate lock."""
        user = self.instance
        if not user:
            return attrs

        lat_in_payload = 'latitude' in attrs
        lng_in_payload = 'longitude' in attrs
        new_lat = attrs.get('latitude') if lat_in_payload else user.latitude
        new_lng = attrs.get('longitude') if lng_in_payload else user.longitude

        coords_changed = (new_lat != user.latitude) or (new_lng != user.longitude)
        if coords_changed and user.location_updated_at:
            days_since = (timezone.now() - user.location_updated_at).days
            if days_since < 60:
                remaining = 60 - days_since
                raise serializers.ValidationError(
                    f'You can only change your GPS coordinates once every 60 days. '
                    f'{remaining} day(s) remaining.'
                )
        return attrs

    def update(self, instance, validated_data):
        """Auto-set location_updated_at when coordinates change."""
        new_lat = validated_data.get('latitude')
        new_lng = validated_data.get('longitude')
        coords_changed = False
        if new_lat is not None and new_lat != instance.latitude:
            coords_changed = True
        if new_lng is not None and new_lng != instance.longitude:
            coords_changed = True
        if coords_changed:
            validated_data['location_updated_at'] = timezone.now()
        return super().update(instance, validated_data)
    
    def get_followers_count(self, obj):
        return obj.followers.count()
    
    def get_average_rating(self, obj):
        """
        Store rating = average of ALL reviews related to this store:
          - Direct store reviews (product=null, store=this_user)
          - Reviews on any product from this store
          - Reviews on any pack product from this store (via product.store)
        """
        from catalog.models import Review  # local import to avoid circulars
        from django.db.models import Q

        avg = Review.objects.filter(
            Q(store=obj) | Q(product__store=obj)
        ).aggregate(Avg('rating'))['rating__avg']
        return round(avg, 1) if avg else 0.0

    def get_product_count(self, obj):
        return obj.products.filter(available_status='available').count()

    def get_review_count(self, obj):
        from catalog.models import Review
        from django.db.models import Q
        return Review.objects.filter(Q(store=obj) | Q(product__store=obj)).count()

    def get_categories(self, obj):
        """Distinct category names of the store's available products."""
        return list(
            obj.products.filter(available_status='available')
               .exclude(category__isnull=True)
               .values_list('category__name', flat=True)
               .distinct()
        )


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    username = serializers.CharField(required=False, allow_blank=True)
    name = serializers.CharField(required=True, max_length=255)
    preferred_categories = serializers.ListField(
        child=serializers.IntegerField(), required=False, write_only=True
    )

    gender = serializers.ChoiceField(choices=['male', 'female', 'other'], required=True)
    birthday = serializers.DateField(required=True)

    class Meta:
        model = User
        fields = ['username', 'name', 'email', 'phone', 'gender', 'birthday', 'password', 'preferred_categories']

    def validate_name(self, value):
        if not value or len(value.strip()) < 2:
            raise serializers.ValidationError('الاسم يجب أن يكون حرفين على الأقل')
        return value.strip()

    def validate_email(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError('البريد الإلكتروني مطلوب')
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('هذا البريد الإلكتروني مسجل مسبقاً')
        return value

    def validate_phone(self, value):
        if not value or not str(value).strip():
            raise serializers.ValidationError('رقم الهاتف مطلوب')
        return str(value).strip()

    def validate_birthday(self, value):
        # Keep it minimal: require a date in the past.
        from datetime import date
        if value >= date.today():
            raise serializers.ValidationError('تاريخ الميلاد غير صالح')
        return value

    def validate(self, attrs):
        # Auto-generate username from email if not provided
        username = attrs.get('username', '').strip()
        email = attrs.get('email', '')
        
        if not username and email:
            # Generate username from email prefix + unique suffix
            base_username = email.split('@')[0].replace('.', '_').replace('-', '_')
            username = base_username
            # Ensure uniqueness
            counter = 1
            while User.objects.filter(username=username).exists():
                username = f"{base_username}_{counter}"
                counter += 1
            attrs['username'] = username
        elif not username:
            # Fallback to UUID-based username
            attrs['username'] = f"user_{uuid.uuid4().hex[:8]}"
        
        return attrs

    def create(self, validated_data):
        from analytics.models import UserInterestProfile
        password = validated_data.pop('password')
        preferred_categories = validated_data.pop('preferred_categories', [])
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        if preferred_categories:
            UserInterestProfile.objects.create(
                user=user,
                category_scores={str(cat_id): 50 for cat_id in preferred_categories},
            )
        return user


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for password change endpoint"""
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True, min_length=8)
    confirm_password = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError({
                'confirm_password': 'كلمات المرور غير متطابقة'
            })
        if attrs['old_password'] == attrs['new_password']:
            raise serializers.ValidationError({
                'new_password': 'كلمة المرور الجديدة يجب أن تكون مختلفة عن الحالية'
            })
        return attrs


class FollowerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Follower
        fields = ['id', 'user', 'followed_user', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class SendPhoneOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

    def validate_phone(self, value):
        phone = normalize_phone(value)
        if not phone:
            raise serializers.ValidationError('الرقم الجزائري يجب أن يكون: 05XXXXXXXX أو 06XXXXXXXX أو 07XXXXXXXX')
        return phone


class VerifyPhoneOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    code = serializers.CharField(max_length=6)
    name = serializers.CharField(required=False, allow_blank=True, max_length=255)

    def validate_phone(self, value):
        phone = normalize_phone(value)
        if not phone:
            raise serializers.ValidationError('الرقم الجزائري يجب أن يكون: 05XXXXXXXX أو 06XXXXXXXX أو 07XXXXXXXX')
        return phone

    def validate_code(self, value):
        code = (value or '').strip()
        if len(code) != 6 or not code.isdigit():
            raise serializers.ValidationError('رمز التحقق يجب أن يكون 6 أرقام')
        return code


class PreferredCategoriesSerializer(serializers.Serializer):
    preferred_categories = serializers.ListField(
        child=serializers.IntegerField(min_value=1),
        allow_empty=False,
    )


class StoreReportSerializer(serializers.ModelSerializer):
    reporter = serializers.ReadOnlyField(source='reporter.id')
    reporter_name = serializers.SerializerMethodField()
    store_name = serializers.SerializerMethodField()

    class Meta:
        model = StoreReport
        fields = [
            'id',
            'reporter',
            'reporter_name',
            'store',
            'store_name',
            'reason',
            'details',
            'status',
            'created_at',
        ]
        read_only_fields = ['id', 'reporter', 'reporter_name', 'store_name', 'status', 'created_at']

    def get_reporter_name(self, obj):
        return obj.reporter.name or obj.reporter.username

    def get_store_name(self, obj):
        return obj.store.name or obj.store.username

    def validate(self, attrs):
        request = self.context.get('request')
        reporter = getattr(request, 'user', None)
        store = attrs.get('store')
        if reporter and store and reporter == store:
            raise serializers.ValidationError('You cannot report your own store.')
        return attrs
