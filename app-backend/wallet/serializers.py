from rest_framework import serializers

from .models import CoinPurchase, CoinTransaction


class CoinTransactionSerializer(serializers.ModelSerializer):
	class Meta:
		model = CoinTransaction
		fields = [
			'id',
			'amount_signed',
			'reason',
			'related_model',
			'related_id',
			'created_at',
		]
		read_only_fields = fields


class CoinPurchaseSerializer(serializers.ModelSerializer):
	proof_images = serializers.SerializerMethodField()

	class Meta:
		model = CoinPurchase
		fields = [
			'id',
			'user',
			'pack_id',
			'coins_amount',
			'price_amount',
			'payment_note',
			'status',
			'approved_at',
			'approved_by',
			'proof_images',
			'created_at',
		]
		read_only_fields = fields

	def get_proof_images(self, obj):
		return [proof.image.url for proof in obj.proofs.all() if proof.image]


class CoinPurchaseApproveSerializer(serializers.Serializer):
	purchase_id = serializers.IntegerField(required=False)
