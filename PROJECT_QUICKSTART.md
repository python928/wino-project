# Wino / Toprice — Project Quickstart

Last updated: 2026-03-23

## What this repo contains
- Backend API: `app-backend/` (Django 5 + DRF + JWT)
- Flutter client: `the_app/` (Provider/ChangeNotifier + named routes)

Core rule: **Store == User** (`users.User` is the “store”).

---

## Backend quickstart (local)
From `app-backend/`:

1) Install Python dependencies
- `pip3 install -r requirements.txt --break-system-packages --default-timeout 300`

2) Migrate database
- `python3 manage.py migrate`

3) Run server
- `python3 manage.py runserver 0.0.0.0:8000`

Key environment behavior
- Default DB is SQLite (`app-backend/db.sqlite3`).
- Media is served only when `DEBUG=True`.

---

## Flutter quickstart
From `the_app/`:

1) Fetch packages
- `flutter pub get`

2) Set API base URL
- Edit `the_app/lib/core/config/api_config.dart` (`ApiConfig.baseUrl`) to match your machine IP/port.

3) Run
- Android: `flutter run`
- Web: `flutter run -d chrome`

---

## Most used API roots
- Auth: `/api/auth/token/`, `/api/auth/token/refresh/`
- Users: `/api/users/`
- Catalog: `/api/catalog/`
- Ads: `/api/ads/`
- Wallet: `/api/wallet/`
- Analytics: `/api/analytics/`
- Notifications: `/api/notifications/`

---

## Known integration mismatches (fix before production)
- Flutter config includes `/api/subscriptions/plans/` and `/api/subscriptions/payment-requests/`.
- Current backend router under `/api/subscriptions/` exposes only `merchant-subscriptions`.

---

## OTP note (current dev/testing mode)
OTP generation/delivery is currently in a testing mode in server code (fixed code + delivery disabled). This must be switched to real delivery + secure rules before production.
