from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.validators import FileExtensionValidator
from rest_framework import permissions, status
from rest_framework.decorators import api_view, parser_classes, permission_classes
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response

from .models import CoinPackPlan, CoinPurchase, CoinPurchaseProof
from .serializers import (
	CoinPurchaseApproveSerializer,
	CoinPurchaseSerializer,
	CoinTransactionSerializer,
)
from .services import (
	approve_coin_purchase,
	create_coin_purchase,
	get_coin_costs,
	get_wallet_snapshot,
	grant_coins,
)


def _coin_packs():
	default_packs = [
		{'id': 'post_50', 'coins': 50, 'price': '500'},
		{'id': 'post_120', 'coins': 120, 'price': '1000'},
		{'id': 'ad_200', 'coins': 200, 'price': '700'},
		{'id': 'ad_500', 'coins': 500, 'price': '1500'},
	]
	plans = CoinPackPlan.objects.filter(is_active=True).order_by('sort_order', 'coins_amount', 'id')
	if plans.exists():
		packs = []
		for plan in plans:
			original_price = plan.original_price_amount
			percent_saved = 0.0
			if original_price and original_price > 0 and plan.price_amount >= 0:
				try:
					percent_saved = max(
						0.0,
						round((float(original_price) - float(plan.price_amount)) / float(original_price) * 100.0, 2),
					)
				except Exception:
					percent_saved = 0.0
			packs.append(
				{
					'id': plan.pack_id,
					'coins': int(plan.coins_amount or 0),
					'price': str(plan.price_amount),
					'original_price': str(original_price) if original_price is not None else None,
					'percent_saved': percent_saved,
					'is_promoted': bool(plan.is_promoted),
					'promo_badge': plan.promo_badge,
					'title': plan.title,
				}
			)
		return packs

	configured = getattr(settings, 'COIN_PACKS', default_packs)
	if isinstance(configured, dict):
		flat = []
		for value in configured.values():
			if isinstance(value, list):
				flat.extend(value)
		return flat
	if isinstance(configured, list):
		return configured
	return default_packs


MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024
ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'webp']


def _validate_proof_image(image):
	validator = FileExtensionValidator(allowed_extensions=ALLOWED_EXTENSIONS)
	validator(image)
	if getattr(image, 'size', 0) > MAX_IMAGE_SIZE_BYTES:
		raise ValueError(
			f'Image "{getattr(image, "name", "file")}" exceeds 5MB limit.'
		)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def wallet_snapshot(request):
	snapshot = get_wallet_snapshot(request.user, limit=20)
	tx = snapshot['recent_transactions']
	purchases = snapshot['recent_purchases']
	serialized = CoinTransactionSerializer(tx, many=True).data
	purchases_data = CoinPurchaseSerializer(purchases, many=True).data
	return Response(
		{
			'coins_balance': snapshot['coins_balance'],
			'post_coins_balance': snapshot['post_coins_balance'],
			'ad_view_coins_balance': snapshot['ad_view_coins_balance'],
			'recent_transactions': serialized,
			'recent_purchases': purchases_data,
			'costs': get_coin_costs(),
		}
	)


@api_view(['POST'])
@permission_classes([permissions.IsAdminUser])
def wallet_grant(request):
	amount = int(request.data.get('amount') or 0)
	reason = str(request.data.get('reason') or 'admin_grant')
	user_id = request.data.get('user_id') or request.data.get('user')
	if amount <= 0:
		return Response({'detail': 'Amount must be > 0.'}, status=status.HTTP_400_BAD_REQUEST)
	target = request.user
	if user_id is not None:
		User = get_user_model()
		try:
			target = User.objects.get(id=user_id)
		except User.DoesNotExist:
			return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
	grant_coins(target, amount=amount, reason=reason)
	return Response({'status': 'ok', 'user_id': target.id})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def wallet_buy(request):
	pack_id = str(request.data.get('pack_id') or '')
	packs = _coin_packs()
	pack = next((p for p in packs if str(p.get('id')) == pack_id), None)
	if pack is None:
		return Response({'detail': 'Invalid pack_id.'}, status=status.HTTP_400_BAD_REQUEST)

	coins_amount = int(pack.get('coins') or 0)
	price_amount = pack.get('price') or 0
	images = request.FILES.getlist('images')
	if not images:
		return Response(
			{'images': 'Please upload at least 1 image as payment proof.'},
			status=status.HTTP_400_BAD_REQUEST,
		)
	if len(images) > 3:
		return Response(
			{'images': 'You can upload up to 3 images.'},
			status=status.HTTP_400_BAD_REQUEST,
		)
	try:
		for image in images:
			_validate_proof_image(image)
	except Exception as exc:
		return Response({'images': str(exc)}, status=status.HTTP_400_BAD_REQUEST)

	purchase = create_coin_purchase(
		request.user,
		pack_id=pack_id,
		coins_amount=coins_amount,
		price_amount=price_amount,
		payment_note=str(request.data.get('payment_note') or ''),
	)
	for image in images:
		CoinPurchaseProof.objects.create(purchase=purchase, image=image)

	return Response(
		{
			'purchase': CoinPurchaseSerializer(purchase).data,
			'message': 'Purchase request submitted and pending server approval.',
		},
		status=status.HTTP_201_CREATED,
	)


@api_view(['POST'])
@permission_classes([permissions.IsAdminUser])
def wallet_approve_purchase(request, purchase_id=None):
	data = request.data if isinstance(request.data, dict) else {}
	input_serializer = CoinPurchaseApproveSerializer(data=data)
	input_serializer.is_valid(raise_exception=True)

	target_id = purchase_id or input_serializer.validated_data.get('purchase_id')
	if not target_id:
		return Response({'detail': 'purchase_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

	try:
		purchase = CoinPurchase.objects.select_related('user').get(id=target_id)
	except CoinPurchase.DoesNotExist:
		return Response({'detail': 'Purchase not found.'}, status=status.HTTP_404_NOT_FOUND)

	purchase, credited = approve_coin_purchase(purchase, approver=request.user)
	return Response(
		{
			'purchase': CoinPurchaseSerializer(purchase).data,
			'credited': credited,
		}
	)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def wallet_packs(_request):
	return Response({'packs': _coin_packs()})
