from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from analytics.recommendations import get_recommended_products
from analytics.serializers import RecommendationItemSerializer


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
