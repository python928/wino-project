from django.contrib.auth import get_user_model
from rest_framework import serializers
import uuid

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'name', 'email', 'phone', 'role', 'profile_image', 'date_joined']
        read_only_fields = ['id', 'date_joined']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    username = serializers.CharField(required=False, allow_blank=True)
    name = serializers.CharField(required=True, max_length=255)

    class Meta:
        model = User
        fields = ['username', 'name', 'email', 'password', 'phone', 'role']

    def validate_name(self, value):
        if not value or len(value.strip()) < 2:
            raise serializers.ValidationError('الاسم يجب أن يكون حرفين على الأقل')
        return value.strip()

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('هذا البريد الإلكتروني مسجل مسبقاً')
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
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
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
