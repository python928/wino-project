from rest_framework import serializers

from .models import Follower, Store


class StoreSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.id')

    class Meta:
        model = Store
        fields = ['id', 'owner', 'name', 'description', 'address', 'latitude', 'longitude', 'type', 'profile_image', 'cover_image', 'created_at']
        read_only_fields = ['id', 'owner', 'created_at']


class FollowerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Follower
        fields = ['id', 'user', 'store', 'created_at']
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        # Prevent duplicates by leveraging unique_together
        return super().create(validated_data)
