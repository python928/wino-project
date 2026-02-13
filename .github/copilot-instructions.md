# Copilot instructions (toprice)

## Repo layout (monorepo)
- `app-backend/`: Django 5 + Django REST Framework API (JWT auth via SimpleJWT).
- `the_app/`: Flutter client app (Provider/ChangeNotifier state management).

## Backend (Django/DRF)
- Entrypoints: `app-backend/manage.py` uses `DJANGO_SETTINGS_MODULE=backend.settings`.
- URL routing lives in `app-backend/backend/urls.py`; each app exposes a DRF `DefaultRouter` in `*/urls.py` (example: `app-backend/users/urls.py`, `app-backend/catalog/urls.py`).
- Auth is JWT:
  - Token: `POST /api/auth/token/`
  - Refresh: `POST /api/auth/token/refresh/`
  - Register: `POST /api/users/register/`
- Default permissions are authenticated (`REST_FRAMEWORK.DEFAULT_PERMISSION_CLASSES = IsAuthenticated`). Public endpoints explicitly override permissions in their viewsets (example: `catalog.views.ProductViewSet` allows `list/retrieve`).
- Domain convention: **Store == User**. The store profile fields are on `users.User` (see `app-backend/users/models.py`), and API endpoints/clients often use “store” to mean “user id”.
- DB is SQLite by default (`db.sqlite3`). If `POSTGRES_NAME` is set, settings switch to Postgres (see `app-backend/backend/settings.py`). `app-backend/docker-compose.yml` wires Postgres and also includes Redis (Redis is not referenced by settings today).
- Media files are served from `/media/` only when `DEBUG=True` (see `backend/urls.py`).
- Important mismatch to keep in mind: messaging/notifications apps exist, but their routes are currently commented out in `app-backend/backend/urls.py`. The Flutter client still references `/api/messaging/...` and `/api/notifications/...` in `ApiConfig`.

## Flutter app (Provider + named routes)
- `the_app/lib/main.dart` wires `MultiProvider` with `AuthProvider`, `PostProvider`, `HomeProvider`, `StoreProvider`, `PackProvider`, `MessageProvider`.
- Routing uses named routes + central generator:
  - Route names: `the_app/lib/core/routing/routes.dart`
  - Route mapping/transitions: `the_app/lib/core/routing/route_generator.dart`
  - `MaterialApp.onGenerateRoute` points at a wrapper `the_app/lib/core/navigation/route_generator.dart` that delegates to the legacy generator.
  - Keep argument conventions (examples):
    - `Routes.store`: `int storeId` OR `{storeId: int}`
    - `Routes.productDetails`: expects a `Post`
    - `Routes.packDetails`: expects a `Pack`
    - `Routes.searchTab`: expects `{query, type, autoSearch}`
  - `go_router` is present in dependencies but the app currently uses `onGenerateRoute`; don’t refactor routing unless explicitly requested.
- API integration:
  - Base URLs/endpoints: `the_app/lib/core/config/api_config.dart` (web: `http://localhost:8000`, android emulator: `http://10.0.2.2:8000`).
  - HTTP client: `the_app/lib/core/services/api_service.dart` uses `package:http` and auto-retries once by refreshing tokens on 401.
  - Tokens/storage: `StorageService` uses `flutter_secure_storage` for JWTs and `SharedPreferences` for non-sensitive user state (`the_app/lib/core/services/storage_service.dart`).
  - DRF pagination: client code often accepts either `{results: [...]}` or a raw list (example: `StoreApiService.getStoreProducts`). Preserve this when adding new list endpoints.

## Developer workflows (known-good commands)
- Backend (local Python):
  - `pip3 install -r requirements.txt --break-system-packages --default-timeout 300`
  - `/usr/bin/python3 manage.py migrate`
  - `/usr/bin/python3 manage.py runserver 0.0.0.0:8000`
- Backend (Docker): `docker compose up --build` from `app-backend/`.
- Flutter:
  - `flutter pub get`
  - `flutter run` (or `flutter run -d chrome` for web)
  - `flutter test`, `flutter analyze`

## Style/conventions to follow
- Don’t “format cleanups” across files; keep changes targeted.
- Some backend Python files use **tabs** for indentation (see `app-backend/users/views.py`). Preserve existing indentation style when editing.
- Dart lints are intentionally relaxed in `the_app/analysis_options.yaml` (prints are allowed; some warnings are ignored).
