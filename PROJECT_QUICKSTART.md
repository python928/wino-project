# Wino / Toprice - Project Quickstart

Last updated: 2026-03-23

## What this repo contains
- Backend API: `app-backend/` (Django 5 + DRF + JWT)
- Flutter client: `the_app/` (Provider/ChangeNotifier + named routes)

Core rule: **Store == User** (`users.User` is the “store”).

## Backend quickstart (local)
From `app-backend/`:

1. Install Python dependencies
- `pip3 install -r requirements.txt --break-system-packages --default-timeout 300`

2. Migrate database
- `python3 manage.py migrate`

3. Run server
- `python3 manage.py runserver 0.0.0.0:8000`

Key environment behavior
- Default DB is SQLite (`app-backend/db.sqlite3`).
- Media is served only when `DEBUG=True`.
- Several production hardening settings are still pending.

## Flutter quickstart
From `the_app/`:

1. Fetch packages
- `flutter pub get`

2. Set API base URL
- Edit `the_app/lib/core/config/api_config.dart` (`ApiConfig.baseUrl`) to match your machine IP/port.

3. If you changed ARB localization files
- `flutter gen-l10n`

4. Run on Android
- `flutter run`

Current platform note
- This repo is Android-only at platform-folder level.
- Some internal names still use legacy identifiers such as `dzlocal_shop`, but the visible product brand is `Wino`.

## Most used API roots
- Auth: `/api/auth/token/`, `/api/auth/token/refresh/`
- Users: `/api/users/`
- Catalog: `/api/catalog/`
- Ads: `/api/ads/`
- Notifications: `/api/notifications/`
- Subscriptions: `/api/subscriptions/`
- Wallet: `/api/wallet/`
- Analytics: `/api/analytics/`
- Feedback: `/api/feedback/`

## Important routing truths
- Device registration: `/api/notifications/devices/`
- Subscription payment requests: `/api/subscriptions/payment-requests/`
- Compatibility alias also exists: `/api/subscriptions/subscription-payment-requests/`
- Merchant dashboard lives under merchant-subscriptions custom actions

## OTP note (current dev/testing mode)
OTP generation/delivery is still not in a final production-ready mode. This must be switched to real delivery + secure verification rules before production.
