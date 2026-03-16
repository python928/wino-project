from rest_framework import serializers

from .models import AdCampaign


class AdCampaignSerializer(serializers.ModelSerializer):
	store = serializers.PrimaryKeyRelatedField(read_only=True)
	kind = serializers.SerializerMethodField()
	target_type = serializers.SerializerMethodField()
	remaining_impressions = serializers.SerializerMethodField()

	class Meta:
		model = AdCampaign
		fields = [
			'id',
			'store',
			'product',
			'pack',
			'target_type',
			'name',
			'description',
			'percentage',
			'kind',
			'placement',
			'audience_mode',
			'age_from',
			'age_to',
			'geo_mode',
			'target_wilayas',
			'target_radius_km',
			'target_categories',
			'priority_boost',
			'is_active',
			'start_date',
			'end_date',
			'max_impressions',
			'unique_viewers_count',
			'impressions_count',
			'clicks_count',
			'remaining_impressions',
			'created_at',
		]
		read_only_fields = [
			'id',
			'created_at',
			'unique_viewers_count',
			'impressions_count',
			'clicks_count',
			'remaining_impressions',
			'kind',
			'target_type',
		]

	def get_kind(self, _obj):
		return 'advertising'

	def get_target_type(self, obj):
		if obj.product_id:
			return 'product'
		if obj.pack_id:
			return 'pack'
		return 'unknown'

	def validate(self, attrs):
		product = attrs.get('product', getattr(self.instance, 'product', None))
		pack = attrs.get('pack', getattr(self.instance, 'pack', None))
		if bool(product) == bool(pack):
			raise serializers.ValidationError('Provide exactly one target: product or pack.')
		return attrs

	def get_remaining_impressions(self, obj):
		if obj.max_impressions is None:
			return None
		remaining = int(obj.max_impressions) - int(obj.impressions_count or 0)
		return max(remaining, 0)
