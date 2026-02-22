# Smart Recommendation System — Implementation Report

## Architecture Decision: Server-Side Tracking Only

### Why we removed `/api/analytics/log/`

The original plan included a Flutter → backend log endpoint for tracking user events.
After analysis, **every event the app cares about is already visible on the server**:

| Event | How the server sees it |
|---|---|
| `view` | `GET /api/catalog/products/{id}/` → `ProductViewSet.retrieve()` |
| `search` | `GET /api/catalog/products/?search=keyword` → `ProductViewSet.list()` |
| `filter_price` | `GET /api/catalog/products/?min_price=X&max_price=Y` → `ProductViewSet.list()` |
| `favorite` | Django signal on `Favorite.post_save` |
| `contact` (review) | Django signal on `Review.post_save` |

**Result:** No extra network call from Flutter. No separate log endpoint.
The server captures events naturally from API calls that already exist.

---

## Files Changed

### Backend (`app-backend/`)

#### `backend/urls.py`
- Added: `path('api/analytics/', include('analytics.urls'))`
- Analytics recommendations endpoint is now reachable

#### `catalog/views.py` → `ProductViewSet`
- Added `retrieve()` override → logs `'view'` event when authenticated user opens a product
- Added `list()` override → logs `'search'` when `?search=` param present, logs `'filter_price'` when `?min_price=` or `?max_price=` present
- All logging is wrapped in `try/except` — never breaks existing behavior

#### `analytics/views.py`
- Removed `LogEventAPIView` (endpoint no longer needed)
- Kept only `RecommendationsAPIView`

#### `analytics/urls.py`
- Removed `log/` URL pattern
- Only `/api/analytics/recommendations/` remains

#### `analytics/serializers.py`
- Removed `AnalyticsLogSerializer` (no log endpoint)
- Enhanced `RecommendationItemSerializer` — now returns `store_name` and `image_url`

#### `analytics/recommendations.py`
- Fixed `_calculate_product_score`: seller trust was never computed due to misplaced `if seller_avg:` inside the for loop — moved it after the loop
- Added `.prefetch_related('images', 'reviews', 'promotions')` to avoid N+1 queries

---

### Flutter (`the_app/lib/`)

#### `core/services/analytics_api_service.dart`
- Removed `logEvent()` method (server handles all tracking)
- Fixed `StorageService` usage: was calling `_storage.getToken()` on an instance, but `StorageService` is all-static — fixed to `StorageService.getAccessToken()`

#### `features/analytics/providers/analytics_provider.dart`
- Removed `logEvent()` method — no longer needed
- Kept only `fetchRecommendations()`

#### `features/analytics/analytics_export.dart`
- Removed exports for `view_tracker.dart` and `search_tracker.dart`

#### `features/analytics/widgets/view_tracker.dart`
- Simplified to no-op (server tracks views via `retrieve()`)

#### `features/analytics/widgets/search_tracker.dart`
- Simplified to no-op (server tracks searches via `list()`)

#### `main.dart`
- Added `AnalyticsProvider` to `MultiProvider`

#### `presentation/home/home_screen.dart`
- Added `RecommendationsList()` widget after the "Latest Products" section

---

## API Endpoints (Final)

| Method | URL | Auth | Description |
|---|---|---|---|
| `GET` | `/api/analytics/recommendations/` | Required | Personalized product list |
| `GET` | `/api/analytics/recommendations/?limit=10` | Required | Limit results |
| `GET` | `/api/analytics/recommendations/?category_id=3` | Required | Filter by category |

---

## How It Works End-to-End

```
User opens app
     │
     ▼
[Home Screen]
  ├─ loads products → GET /api/catalog/products/
  │     └─ server logs nothing (no ?search, no auth filter)
  └─ loads RecommendationsList → GET /api/analytics/recommendations/
        └─ returns personalized top products (cold start for new users)

User searches "samsung"
     │ GET /api/catalog/products/?search=samsung
     ▼
ProductViewSet.list()
  ├─ returns results (DRF handles filtering)
  └─ logs InteractionLog(user, action='search', metadata={'keyword':'samsung'})

User opens product detail
     │ GET /api/catalog/products/42/
     ▼
ProductViewSet.retrieve()
  ├─ returns product data
  └─ logs InteractionLog(user, action='view', product=<Product:42>)

User applies price filter
     │ GET /api/catalog/products/?min_price=5000&max_price=20000
     ▼
ProductViewSet.list()
  ├─ returns filtered results
  └─ logs InteractionLog(user, action='filter_price', metadata={'min':5000,'max':20000})

User favorites a product
     │ POST /api/catalog/favorites/toggle/
     ▼
Django Signal (post_save on Favorite)
  └─ logs InteractionLog(user, action='favorite', product=<Product>)

[Background] python manage.py update_profiles
     │
     ▼
Reads last 30 days of InteractionLog
  └─ Computes UserInterestProfile (category_scores, price_affinity, ...)

Next time user opens app
     │ GET /api/analytics/recommendations/
     ▼
Recommendation engine reads UserInterestProfile
  └─ Returns top 20 personalized products with match reasons
```

---

## Running / Setup

```bash
# 1. Apply analytics migrations (already done — 0001_initial.py exists)
cd app-backend
python manage.py migrate

# 2. Seed demo data for testing
python manage.py seed_analytics

# 3. Compute user profiles (run periodically in production)
python manage.py update_profiles

# 4. Test the endpoint
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/api/analytics/recommendations/
```

---

## Recommendation Algorithm (Quick Reference)

```
Score = Σ(Weight × Component)

Category match   × 0.30  →  based on user's interaction history
Price match      × 0.15  →  matches user's price range preference
Quality rating   × 0.15  →  product avg rating × confidence
Recency          × 0.10  →  how new the listing is
Popularity       × 0.10  →  interactions in last 7 days
Seller trust     × 0.10  →  seller avg rating
Negotiable       × 0.05  →  Algerian market feature
Promotion        × 0.05  →  active discount percentage

Cold start (new user) → trending products from last 7 days
Diversification → max 4 products per seller in results
Recently viewed → excluded from recommendations (last 6 hours)
```

---

## What's Tracked Automatically (No Extra Code Needed)

| Action | Trigger |
|---|---|
| Product view | Opening any product detail page |
| Search | Using the search bar |
| Price filter | Applying min/max price filters |
| Favorite | Adding to favorites |
| Contact/review | Writing a review |

Future events to add (when new API endpoints are created):
- `negotiate` — when negotiation endpoint is added
- `filter_wilaya` — when wilaya filter param is added to catalog
- `filter_rating` — when rating filter param is added to catalog
- `filter_dist` — when distance/radius filter is added
