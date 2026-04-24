from rest_framework import serializers

from .models import AdCampaign


class AdCampaignSerializer(serializers.ModelSerializer):
	store = serializers.PrimaryKeyRelatedField(read_only=True)
	kind = serializers.SerializerMethodField()
	target_type = serializers.SerializerMethodField()
	remaining_impressions = serializers.SerializerMethodField()
	product_name = serializers.SerializerMethodField()
	display_hours = serializers.ListField(
		child=serializers.IntegerField(min_value=0, max_value=23),
		required=False,
		allow_empty=False,
	)

	class Meta:
		model = AdCampaign
		fields = [
			'id',
			'store',
			'product',
			'product_name',
			'pack',
			'target_type',
			'name',
			'description',
			'percentage',
			'kind',
			'display_hours',
			'audience_mode',
			'age_from',
			'age_to',
			'geo_mode',
			'target_wilayas',
			'target_radius_km',
			'target_categories',
			'is_active',
			'max_impressions',
			'unique_viewers_count',
			'impressions_count',
			'delivered_views_count',
			'clicks_count',
			'remaining_impressions',
			'created_at',
		]
		read_only_fields = [
			'id',
			'created_at',
			'unique_viewers_count',
			'impressions_count',
			'delivered_views_count',
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

	def get_product_name(self, obj):
		if obj.product is not None:
			return getattr(obj.product, 'name', '')
		if obj.pack is not None:
			return getattr(obj.pack, 'name', '')
		return ''

	def validate(self, attrs):
		# Validate that only one of product or pack is targeted via serializers
		product = attrs.get('product', getattr(self.instance, 'product_id', None))
		pack = attrs.get('pack', getattr(self.instance, 'pack_id', None))
		
		has_product = product is not None
		has_pack = pack is not None
		if has_product == has_pack:
			raise serializers.ValidationError('Ad campaign must target exactly one of product or pack.')

		display_hours = attrs.get('display_hours')
		if display_hours is not None:
			normalized_hours = sorted(set(int(hour) for hour in display_hours))
			if not normalized_hours:
				raise serializers.ValidationError({'display_hours': 'Select at least one display hour.'})
			attrs['display_hours'] = normalized_hours
		
		return attrs

		display_hour = attrs.get('display_hour', getattr(self.instance, 'display_hour', 12))
		if display_hour is None:
			display_hour = 12
		attrs['display_hour'] = int(display_hour)

		existing_hours = getattr(self.instance, 'display_hours', None)
		if existing_hours:
			attrs['display_hours'] = sorted(set(int(hour) for hour in existing_hours))
		else:
			attrs['display_hours'] = [attrs['display_hour']]
		return attrs

	def get_remaining_impressions(self, obj):
		if obj.max_impressions is None:
			return None
		remaining = int(obj.max_impressions) - int(obj.impressions_count or 0)
		return max(remaining, 0)
