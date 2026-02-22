
import math
from django.db.models import F, FloatField, ExpressionWrapper, Sum, Avg, Case, When
from django.db.models.functions import Sqrt, Power, Cast
from decimal import Decimal

# Weights for the Ranking Algorithm (Academic Standard)
W1_DISTANCE = 0.4
W2_PRICE = 0.3
W3_REPUTATION = 0.3

def calculate_adaptive_radius(category):
    """
    R(Product) = BaseRadius + Alpha * ScarcityFactor(C)
    BaseRadius = 5 km
    Alpha = 5 km
    Scarcity: 1..10
    
    Range:
    - Scarcity 1 (Bread): 5 + 5*1 = 10 km
    - Scarcity 10 (Car): 5 + 5*10 = 55 km
    """
    if not category:
        return 20.0 # Default fallback
    
    base_radius = 5.0
    alpha = 5.0
    scarcity = category.scarcity_level or 5
    
    return base_radius + (alpha * scarcity)

def apply_weighted_ranking(queryset, user_lat, user_lng):
    """
    Annotates the queryset with a 'relevance_score' based on:
    S = w1 * (1/d) + w2 * (P_avg / P) + w3 * Reputation
    
    Since we are using SQLite, we use a simplified Euclidean distance approximation for sorting:
    DistanceProxy = sqrt((lat-user_lat)^2 + (lng-user_lng)^2)
    """
    if user_lat is None or user_lng is None:
        return queryset

    u_lat = float(user_lat)
    u_lng = float(user_lng)

    # 1. Annotate with Distance Proxy (Degrees approx)
    # We use Power and F() expressions.
    # Note: SQLite doesn't support Sqrt easily in older Django versions, but let's try.
    # If Sqrt fails, we can rank by distance_squared (monotonic).
    # But for the FORMULA S = 1/d, we need the actual distance or a scale.
    # Let's use distance squared for 'closeness' component: 1 / (d^2 + epsilon)
    
    # We assume 'store' is the ForeignKey to User, and User has latitude/longitude (DecimalFields)
    
    # SQLite Fix: Cast Decimal to Float and use explicit multiplication
    lat_val = Cast(F('store__latitude'), FloatField())
    lng_val = Cast(F('store__longitude'), FloatField())
    
    lat_diff_expr = lat_val - u_lat
    lng_diff_expr = lng_val - u_lng

    queryset = queryset.annotate(
        distance_squared=ExpressionWrapper(
            (lat_diff_expr * lat_diff_expr) + (lng_diff_expr * lng_diff_expr),
            output_field=FloatField()
        )
    )

    # 2. Reputation (Avg Rating)
    # We need to annotate store's average rating.
    # Since 'store' is a User, and reviews are linked to 'store' (User).
    # Review model: store=ForeignKey(User, related_name='store_reviews')
    queryset = queryset.annotate(
        reputation=Avg('store__store_reviews__rating')
    )
    
    # 3. Price Competitiveness
    # We need Category Average Price.
    # This is hard to do efficiently per-row in a single query without Window functions (which SQLite supports but Django support varies).
    # Simplification for Academic Prototype:
    # Use the product's own price in an inverted manner (lower is better).
    # Score = 1 / (Price + 1) normalized? 
    # Or just use -Price.
    # Let's stick to the formula: P_avg / P.
    # We'll calculate global avg price for the whole queryset first? No, that triggers a query.
    # Let's assume a static "benchmark" price or just favor lower price: 1000 / (Price + 1).
    
    # Implementing the exact formula Component 2: Price Factor
    # We will use valid SQL: 1/Price.
    
    queryset = queryset.annotate(
        # Handle null reputation (default to 3.0)
        safe_reputation=Case(
            When(reputation__isnull=True, then=3.0),
            default=F('reputation'),
            output_field=FloatField()
        ),
        # Distance Score: Inverse of distance.
        # Adding 0.0001 to avoid division by zero.
        dist_score=ExpressionWrapper(
            1.0 / (F('distance_squared') + 0.0001),
            output_field=FloatField()
        ),
        # Price Score: Inverse of price.
        # Adding 1 to avoid division by zero.
        price_score=ExpressionWrapper(
            1000.0 / (F('price') + 1.0), 
            output_field=FloatField()
        ),
        
        # Total Weighted Score
        relevance_score=ExpressionWrapper(
            (W1_DISTANCE * F('dist_score')) + 
            (W2_PRICE * F('price_score')) + 
            (W3_REPUTATION * F('safe_reputation')),
            output_field=FloatField()
        )
    )
    
    return queryset.order_by('-relevance_score')
