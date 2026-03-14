from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from analytics.scoring import update_user_profile
from analytics.recommendations import get_recommended_products
from analytics.serializers import InteractionEventSerializer, RecommendationItemSerializer
from analytics.utils import log_user_event, normalize_discovery_mode


class RecommendationsAPIView(APIView):
	"""
	GET /api/analytics/recommendations/

	Returns a personalized ranked list of products for the authenticated user.
	For new users with no history, returns trending products (cold start).

	Query params:
	  limit       (int, default 20) — number of results
	  category_id (int, optional)  — restrict to a single category
	"""
	permission_classes = [IsAuthenticated]

	def get(self, request):
		limit = request.query_params.get('limit', 20)
		category_id = request.query_params.get('category_id')

		try:
			limit = int(limit)
		except (ValueError, TypeError):
			limit = 20

		category_filter = None
		if category_id is not None and str(category_id).strip():
			try:
				category_filter = int(category_id)
			except (ValueError, TypeError):
				category_filter = None

		items = get_recommended_products(
			request.user,
			limit=limit,
			category_filter=category_filter,
		)
		serializer = RecommendationItemSerializer(items, many=True, context={'request': request})
		return Response(serializer.data)


class InteractionEventAPIView(APIView):
	"""
	POST /api/analytics/events/

	Client-side event logging endpoint used for contextual analytics
	(nearby/location mode, search query, distance, wilaya, etc.).
	"""
	permission_classes = [IsAuthenticated]

	def post(self, request):
		raw_events = request.data
		if isinstance(request.data, dict) and isinstance(request.data.get('events'), list):
			raw_events = request.data.get('events') or []
		if not isinstance(raw_events, list):
			raw_events = [raw_events]

		serializer = InteractionEventSerializer(data=raw_events, many=True)
		serializer.is_valid(raise_exception=True)
		events = serializer.validated_data

		strong_seen = False
		for data in events:
			metadata = dict(data.get('metadata') or {})
			metadata['discovery_mode'] = normalize_discovery_mode(metadata.get('discovery_mode'))
			if data.get('store'):
				metadata.setdefault('store_id', data['store'].id)
			if data.get('category'):
				metadata.setdefault('category_id', data['category'].id)

			log_user_event(
				user=request.user,
				action=data['action'],
				product=data.get('product'),
				metadata=metadata,
				session_id=data.get('session_id', ''),
			)
			if data['action'] in {
				'view',
				'click',
				'promotion_click',
				'search',
				'filter_price',
				'filter_dist',
				'filter_wilaya',
				'filter_rating',
				'favorite',
				'rate',
				'follow_store',
				'contact',
				'negotiate',
			}:
				strong_seen = True

		if strong_seen:
			try:
				update_user_profile(request.user)
			except Exception:
				pass

		return Response({'logged': True, 'count': len(events)})
