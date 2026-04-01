# Wino / Toprice - Project Quickstart

Last updated: 2026-04-01

## What this repo contains
- Backend API: `app-backend/` (Django 5 + DRF + JWT)
- Flutter client: `the_app/` (Provider/ChangeNotifier + named routes)

Core rule: **Store == User** (`users.User` is the “store”).

## Current stage truth
Before you over- or under-state the repo:
- Wino is a serious implemented Android-first platform.
- The UI/UX foundation improved significantly.
- The project is still best described as advanced pre-production with a realistic pilot path.
- It is not yet honest to call it a finished production-ready commercial release.

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

## 2026-03-30 Maps Directions Update
- The Flutter app now includes reusable external Google Maps directions support on store-linked detail pages.
- Main implementation files: `the_app/lib/core/services/external_maps_service.dart` and `the_app/lib/presentation/shared_widgets/directions_button.dart`.
- Recovery fallback: when Maps is unavailable or GPS is disabled, the app launches device settings with localized instructions.
- When validating the app manually, include a GPS-off scenario and confirm the localized "Open Settings" recovery path works without crashes.

## 2026-04-01 Multinational Localization Coverage Update
- Comprehensive localization now covers all core user-facing screens (English, French, Arabic).
- 11 primary high-traffic screens fully localized: home, profile, product/pack/promotion details, favorites, wallet, edit customer/merchant profiles, ads dashboard, notifications, coin payment.
- ~60 new French and Arabic entries added to RuntimeTranslations fallback system.
- All user feedback messages (favorite toggles, follow actions, review submissions, image uploads, payment requests, error states) display localized text.
- Implementation pattern: `context.tr('English key')` with RuntimeTranslations._fr/_ar maps as fallback for screens not yet migrated to ARB-generated localization.
- Secondary screens (add product, add promotion, auth flows, reviews) remain partial and should be audited in a future pass.

## 2026-04-01 Auth And Category Flow Update
- Auth flow structure is now stronger through `the_app/lib/presentation/auth/widgets/auth_flow_components.dart`.
- Category selection is now context-aware and reused across auth, search, and product publishing rather than behaving like a generic picker everywhere.
