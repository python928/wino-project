from django.contrib.auth import get_user_model
from rest_framework import serializers
import uuid
from django.db.models import Avg
from .models import Follower

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    followers_count = serializers.SerializerMethodField()
    average_rating = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'name', 'email', 'phone', 'profile_image', 
            'gender', 'birthday',
            'store_description', 'address', 'latitude', 'longitude', 
            'store_type', 'cover_image', 'followers_count', 'average_rating', 
            'date_joined'
        ]
        read_only_fields = ['id', 'date_joined', 'followers_count', 'average_rating']
    
    def get_followers_count(self, obj):
        return obj.followers.count()
    
    def get_average_rating(self, obj):
        # Store == User: compute avg rating for this store/user from reviews.
        from catalog.models import Review  # local import to avoid circulars
        avg = Review.objects.filter(store=obj).aggregate(Avg('rating'))['rating__avg']
        return round(avg, 1) if avg else 0.0


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
