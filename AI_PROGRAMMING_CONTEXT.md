# AI Programming Context (Toprice/Wino)

## Purpose
This file is a quick high-signal context pack for AI coding agents working on this repository.

## Monorepo overview
- `app-backend/`: Django + DRF backend.
- `the_app/`: Flutter Android client.

## Critical domain rule
- `Store == User` everywhere.

## Backend quick map
- Main urls: `app-backend/backend/urls.py`
- Users/auth: `app-backend/users/*`
- Catalog/search/reviews: `app-backend/catalog/*`
- Ads: `app-backend/ads/*`
- Wallet: `app-backend/wallet/*`
- Subscriptions: `app-backend/subscriptions/*`
- Analytics/trust signals: `app-backend/analytics/*`
- Feedback: `app-backend/feedback/*`

## Frontend quick map
- App entry: `the_app/lib/main.dart`
- Routing: `the_app/lib/core/routing/route_generator.dart`
- Config: `the_app/lib/core/config/api_config.dart`
- Locale management: `the_app/lib/core/providers/locale_provider.dart`
- Deep links: `the_app/lib/core/services/deep_link_service.dart`

## Routing conventions
- Product details route accepts `Post` or product id (loader fallback exists).
- Store route accepts store id.
- Feedback routes exist (`feedbackSend`, `feedbackMy`, `qrScan`).

## API consistency notes
- App base URL currently points to local LAN IP.
- Some endpoints may return paginated results or plain lists.
- Keep backwards compatibility in parser logic.

## Coding guardrails
- Preserve `Store == User` assumptions.
- Avoid introducing a separate Store model unless explicitly requested.
- Keep diffs focused; avoid mass refactors unless requested.
- For Flutter localization, use ARB valid key names (camelCase, no dots).

## Release-risk checklist (short)
- Verify routes between app config and backend urls.
- Run `python manage.py check` for backend changes.
- Run `flutter analyze` for affected Dart files.
