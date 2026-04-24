# AI Programming Context (Wino)

Last updated: 2026-04-01

## Purpose
This file is a quick high-signal context pack for AI coding agents working on this repository.

## Current status reality
Canonical stage reference:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`

Use this mental model:
- strong implemented technical platform,
- large UI/UX transformation already landed,
- advanced pre-production / pilot-ready direction,
- not yet honest to label as full production-ready release.

## Monorepo overview
- `wino_backend/`: Django + DRF backend
- `wino_app/`: Flutter Android client

## Critical domain rule
- `Store == User` everywhere

## Current brand / naming reality
- Visible product brand: `Wino`
- App root widget: `WinoApp`
- Android notification channel: `wino_channel`
- Core package/config names now use `wino`

## Backend quick map
- Main urls: `wino_backend/backend/urls.py`
- Users/auth: `wino_backend/users/*`
- Catalog/search/reviews: `wino_backend/catalog/*`
- Ads: `wino_backend/ads/*`
- Wallet: `wino_backend/wallet/*`
- Subscriptions: `wino_backend/subscriptions/*`
- Analytics/trust signals: `wino_backend/analytics/*`
- Feedback: `wino_backend/feedback/*`
- Notifications/devices: `wino_backend/notifications/*`

## Frontend quick map
- App entry: `wino_app/lib/main.dart`
- Routing: `wino_app/lib/core/routing/route_generator.dart`
- Config: `wino_app/lib/core/config/api_config.dart`
- Locale management: `wino_app/lib/core/providers/locale_provider.dart`
- Deep links: `wino_app/lib/core/services/deep_link_service.dart`
- Location UX helper: `wino_app/lib/presentation/common/location_permission_helper.dart`
- Shared auth flow primitives: `wino_app/lib/presentation/auth/widgets/auth_flow_components.dart`
- Shared category picker: `wino_app/lib/presentation/search/category_selection_screen.dart`

## Routing conventions
- Product details route accepts `Post` or product id (loader fallback exists)
- Store route accepts store id
- Feedback routes exist (`feedbackSend`, `feedbackMy`, `qrScan`)
- Active navigation is named-route based, not `go_router`

## API consistency notes
- App base URL currently points to local LAN IP
- Some endpoints may return paginated results or plain lists
- Device registration path should be treated as `/api/notifications/devices/`
- Subscription payment requests use `/api/subscriptions/payment-requests/` with compatibility alias still present in backend

## Localization notes
- Use ARB/generated localization for reusable or shared strings when possible
- Keep runtime translations aligned for legacy screens still calling `context.tr(...)`
- Do not assume new text is automatically covered by one layer only

## Coding guardrails
- Preserve `Store == User` assumptions
- Avoid introducing a separate Store model unless explicitly requested
- Keep diffs focused; avoid mass refactors unless requested
- For Flutter localization, use valid ARB keys and regenerate localizations when needed
- If you change product/promotion/pack detail behavior, inspect the sibling detail screens too

## Release-risk checklist (short)
- Verify routes between app config and backend urls
- Verify localization changes in both layers when applicable
- Verify doc updates if architecture or API contracts changed
- Run `python manage.py check` for backend changes
- Run `flutter analyze` for affected Dart files
