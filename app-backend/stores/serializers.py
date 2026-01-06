from rest_framework import serializers

from .models import Follower, Store


class StoreSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.id')
    followers_count = serializers.SerializerMethodField()
    average_rating = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = ['id', 'owner', 'name', 'description', 'address', 'phone_number', 'latitude', 'longitude', 'type', 'profile_image', 'cover_image', 'created_at', 'followers_count', 'average_rating']
        read_only_fields = ['id', 'owner', 'created_at']

    def get_followers_count(self, obj):
        return obj.followers.count()

    def get_average_rating(self, obj):
        from catalog.models import Review
        reviews = Review.objects.filter(store=obj)
        if reviews.exists():
            return round(sum(r.rating for r in reviews) / reviews.count(), 1)
        return 0


class FollowerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Follower
        fields = ['id', 'user', 'store', 'created_at']
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        # Prevent duplicates by leveraging unique_together
        return super().create(validated_data)
