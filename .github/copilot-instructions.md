# Copilot instructions (Toprice)

## Monorepo Overview
- [wino_backend/](wino_backend) — Django 5 + DRF API with JWT auth.
- [wino_app/](wino_app) — Flutter client using Provider/ChangeNotifier and named routes.
- Shared domain rule: **Store == User**. Store profile fields live on [wino_backend/users/models.py](wino_backend/users/models.py#L1-L52), and the Flutter app treats "store" as a user id.

## Backend (Django/DRF)
- Entrypoint: run [wino_backend/manage.py](wino_backend/manage.py) with `DJANGO_SETTINGS_MODULE=backend.settings`.
- URLs: central router in [wino_backend/backend/urls.py](wino_backend/backend/urls.py#L1-L40); each app exposes a DRF `DefaultRouter` in its own `urls.py` (for example [wino_backend/users/urls.py](wino_backend/users/urls.py), [wino_backend/catalog/urls.py](wino_backend/catalog/urls.py)).
- Auth & users:
  - JWT: `POST /api/auth/token/`, `POST /api/auth/token/refresh/` via `rest_framework_simplejwt`.
  - Registration: `POST /api/users/register/` from the `users` app.
  - Custom user model [User](wino_backend/users/models.py#L1-L52) merges Django auth fields with store profile (address, location, social links); all users are considered store owners.
- Catalog domain:
  - Core models in [wino_backend/catalog/models.py](wino_backend/catalog/models.py#L1-L120): `Category`, `Product`, `ProductImage`, `Promotion`, `Pack`, `Review`, `Favorite`.
  - `Product.store` and `Pack.merchant` both point to `users.User`, matching the "store == user" convention.
- Analytics & recommendations:
  - User preference state lives in [UserInterestProfile](wino_backend/analytics/models.py#L1-L39); interaction events in [InteractionLog](wino_backend/analytics/models.py#L41-L92).
  - The app **does not** send explicit analytics events; instead, views in `catalog` log events server‑side on product list/retrieve, favorites, reviews, etc.
  - Recommendations are exposed under `/api/analytics/recommendations/` (wired in [wino_backend/backend/urls.py](wino_backend/backend/urls.py#L30-L40) and [wino_backend/analytics/urls.py](wino_backend/analytics/urls.py)).
- Notifications & subscriptions:
  - FCM-based notifications live in [wino_backend/notifications](wino_backend/notifications); register devices at `/api/notifications/devices/` (see [wino_backend/README.md](wino_backend/README.md#L22-L30)).
  - Subscription plans + merchant subscriptions are under `/api/subscriptions/` from [wino_backend/subscriptions](wino_backend/subscriptions).
- Permissions & API patterns:
  - Default permission class is `IsAuthenticated`; public endpoints must explicitly override this.
  - DRF pagination is sometimes enabled; many list endpoints return either a `{results: [...]}` payload or a bare list. The Flutter side already handles both, so keep new endpoints consistent.
- Environment & deployment:
  - Local DB defaults to SQLite ([wino_backend/db.sqlite3](wino_backend/db.sqlite3)); setting `POSTGRES_*` env vars switches to Postgres (see [wino_backend/backend/settings.py](wino_backend/backend/settings.py)).
  - [wino_backend/docker-compose.yml](wino_backend/docker-compose.yml) wires Postgres and Redis; Redis is optional and only needed if Celery is enabled.
  - Media is served at `/media/` only when `DEBUG=True` via [django.conf.urls.static](wino_backend/backend/urls.py#L42-L47).

## Flutter App (Wino / wino_app)
- Bootstrap:
  - Main entrypoint [wino_app/lib/main.dart](wino_app/lib/main.dart#L1-L60) initializes `StorageService.init()` then runs `DzLocalApp`.
  - `MultiProvider` wires `AuthProvider`, `PostProvider`, `HomeProvider`, `StoreProvider`, `PackProvider`, and `AnalyticsProvider`.
- Routing:
  - Uses a central `onGenerateRoute` implementation in [wino_app/lib/core/routing/route_generator.dart](wino_app/lib/core/routing/route_generator.dart).
  - Route name constants live in [wino_app/lib/core/routing/routes.dart](wino_app/lib/core/routing/routes.dart).
  - Argument conventions (preserve these when adding screens):
    - `Routes.store` → `int storeId` or `{storeId: int}` in `arguments`.
    - `Routes.productDetails` → a `Post` instance.
    - `Routes.packDetails` → a `Pack` instance.
    - `Routes.searchTab` → `{query, type, autoSearch}` map.
  - `go_router` is in dependencies but **not** used; do not switch routing style unless explicitly requested.
- API integration:
  - Base URLs and paths are centralized in [wino_app/lib/core/config/api_config.dart](wino_app/lib/core/config/api_config.dart#L1-L90):
    - `ApiConfig.baseUrl` currently returns `http://192.168.94.21:8000/` for all platforms (update there for local dev).
    - Path segments match Django routers, e.g. `stores` is just `users`, notifications under `/api/notifications/`, and analytics under `/api/analytics/`.
  - HTTP wrapper [wino_app/lib/core/services/api_service.dart](wino_app/lib/core/services/api_service.dart) uses `package:http`, adds auth headers from `StorageService`, and auto‑retries once on 401 by refreshing tokens.
  - Tokens & local state are handled by [wino_app/lib/core/services/storage_service.dart](wino_app/lib/core/services/storage_service.dart) (`flutter_secure_storage` for JWTs, `SharedPreferences` for other flags).
- Design system & UI:
  - Theme and typography live in [wino_app/lib/core/theme](wino_app/lib/core/theme); use `AppTheme.lightTheme`, `AppColors`, `AppTextStyles`, and `AppConstants` instead of raw literals.
  - Reusable components (skeleton loaders, product cards, bottom sheets, etc.) live in [wino_app/lib/core/components](wino_app/lib/core/components). Prefer composing these over creating ad‑hoc UI.
- Analytics UI:
  - Client-side tracking widgets (e.g. `view_tracker.dart`, `search_tracker.dart`) are mostly no-ops; recommendations are fetched via `AnalyticsProvider.fetchRecommendations()` and rendered on the home screen.

## Developer Workflows
- Backend (local Python), run from [wino_backend](wino_backend):
  - Install deps: `pip3 install -r requirements.txt --break-system-packages --default-timeout 300`.
  - Migrate: `/usr/bin/python3 manage.py migrate`.
  - Run API: `/usr/bin/python3 manage.py runserver 0.0.0.0:8000`.
- Backend (Docker):
  - From [wino_backend](wino_backend), run `docker compose up --build` for Postgres + web.
- Flutter app, run from [wino_app](wino_app):
  - Install deps: `flutter pub get`.
  - Run app: `flutter run` (or `flutter run -d chrome` for web).
  - Quality: `flutter test` and `flutter analyze`.

## Conventions & Gotchas
- Do not apply global formatting or large refactors; keep diffs tight and focused on the requested change.
- Respect existing indentation: some Django files (for example [wino_backend/users/views.py](wino_backend/users/views.py)) use tabs; preserve the current style in each file.
- On the Flutter side, many APIs accept both paginated `{results: [...]}` and bare lists; keep that flexibility when introducing new endpoints or parsing responses.
- The notifications app exists server‑side; if you change `/api/notifications/...` behavior, keep [ApiConfig](wino_app/lib/core/config/api_config.dart#L60-L80) and backend routers in sync.
- When adding new cross‑cutting features (tracking, recommendations, etc.), prefer server‑side derivation from existing API calls rather than new mobile‑only endpoints, consistent with the current analytics architecture.
