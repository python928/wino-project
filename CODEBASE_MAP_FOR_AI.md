# CODEBASE MAP (for AI assistants + memoire)

Last updated: 2026-03-23

This is a practical “where is what” map so an AI assistant (or a new contributor) can make changes without guessing.

## 1) Backend entrypoints
- Django settings: `app-backend/backend/settings.py`
- Root router: `app-backend/backend/urls.py`
- Manage script: `app-backend/manage.py`

## 2) Users / Store / Auth
- Unified Store model: `app-backend/users/models.py` (`User`)
- Views/endpoints: `app-backend/users/views.py`
- Serializers: `app-backend/users/serializers.py`
- Business logic helpers: `app-backend/users/services.py`

Key behaviors
- Store == User (no separate Store model).
- JWT auth: `/api/auth/token/`.
- Phone OTP endpoints live in `users/views.py` (send + verify).

## 3) Coins + Wallet
- Global settings (singleton): `users.SystemSettings`
  - `first_login_coins`
  - `daily_login_coins`
- Daily top-up rule: `users/services.py::check_and_grant_daily_coins()`
  - Triggered by `GET /api/users/me/`
- Wallet implementation: `app-backend/wallet/`
  - Coin packs catalog + buy/approve flow
  - The daily top-up uses wallet-side grant logic to keep transactions consistent

## 4) Catalog (products, packs, reviews)
- Models: `app-backend/catalog/models.py`
- Views: `app-backend/catalog/views.py`
- Serializers: `app-backend/catalog/serializers.py`

API contract notes
- Category serializer returns: `id`, `name`, `icon` (no `parent`).
- Some list endpoints are paginated depending on view settings.

## 5) Ads
- Models: `app-backend/ads/models.py`
- ViewSet: `app-backend/ads/views.py`
- Serializer: `app-backend/ads/serializers.py`

Important endpoint
- Click tracking action: `POST /api/ads/campaigns/{id}/register-click/`

## 6) Analytics + Recommendations
- Models: `app-backend/analytics/models.py`
- Recommendations: `app-backend/analytics/recommendations.py`
- Views: `app-backend/analytics/views.py`

Note
- Some analytics signals are derived server-side from normal endpoint usage.

## 7) Subscriptions
- Router: `app-backend/subscriptions/urls.py`
- ViewSets: `app-backend/subscriptions/views.py`

Current mismatch
- The Flutter app config references `plans` and `payment-requests`, but the backend router currently registers only `merchant-subscriptions`.

## 8) Notifications / Devices
- Notifications app router: `app-backend/notifications/urls.py`
  - `/api/notifications/notifications/`
  - `/api/notifications/devices/`
- Extra devices root: `app-backend/backend/urls.py`
  - `/api/devices/devices/` (DRF router path)

## 9) Flutter entrypoints and patterns
- App bootstrap: `the_app/lib/main.dart`
- Base URL + API paths: `the_app/lib/core/config/api_config.dart`
- HTTP wrapper: `the_app/lib/core/services/api_service.dart`
- Storage/JWT: `the_app/lib/core/services/storage_service.dart`
- Routing: `the_app/lib/core/routing/route_generator.dart` + `routes.dart`
- State management: `the_app/lib/core/providers/*_provider.dart`

Routing note
- `go_router` is in dependencies but the app uses named routes + a custom route generator.

## 10) OTP note (current dev/testing mode)
OTP generation/delivery is currently in a testing mode in server code (fixed code + delivery disabled). Don’t document it as “production-ready” until it’s switched to real delivery + secure verification.
