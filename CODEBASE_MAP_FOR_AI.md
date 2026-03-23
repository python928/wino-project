# CODEBASE MAP FOR AI ASSISTANTS AND NEW CONTRIBUTORS

Last updated: 2026-03-23

This file is the shortest reliable map of “where to go first” in the Wino codebase.

## 1) First truths to keep in mind
- `Store == User`
- Backend is Django/DRF
- App is Flutter Android-first
- Active app routing is `RouteGenerator`, not `go_router`
- Localization is split between:
  - generated ARB localizations
  - `runtime_translations.dart`

If an edit ignores one of those truths, it will usually drift away from how the project actually works.

## 2) Backend entrypoints
- Settings: `app-backend/backend/settings.py`
- Root URLs: `app-backend/backend/urls.py`
- Manage script: `app-backend/manage.py`

Root routes worth remembering
- `/api/users/`
- `/api/catalog/`
- `/api/ads/`
- `/api/notifications/`
- `/api/subscriptions/`
- `/api/wallet/`
- `/api/analytics/`
- `/api/feedback/`
- `/s/{id}/`
- `/p/{id}/`

## 3) Backend modules by concern
### Auth / User / Store / Trust
- Models: `app-backend/users/models.py`
- Views: `app-backend/users/views.py`
- Serializers: `app-backend/users/serializers.py`
- Helpers: `app-backend/users/services.py`
- Abuse helpers: `app-backend/users/abuse.py`
- Trust scoring: `app-backend/users/trust_scoring.py`

Go here for
- OTP
- unified store profile
- followers
- store reports
- trust settings
- verification status

### Catalog
- Models: `app-backend/catalog/models.py`
- Views: `app-backend/catalog/views.py`
- Serializers: `app-backend/catalog/serializers.py`
- URLs: `app-backend/catalog/urls.py`

Go here for
- categories
- products
- packs
- promotions
- reviews
- favorites
- product reports

### Ads
- Models: `app-backend/ads/models.py`
- Views: `app-backend/ads/views.py`
- URLs: `app-backend/ads/urls.py`

### Analytics
- Models: `app-backend/analytics/models.py`
- Views: `app-backend/analytics/views.py`
- URLs: `app-backend/analytics/urls.py`
- Recommendation logic: `app-backend/analytics/recommendations.py`
- Retention cleanup command:
  `app-backend/analytics/management/commands/purge_old_analytics.py`

### Wallet
- Models: `app-backend/wallet/models.py`
- Views: `app-backend/wallet/views.py`
- Services: `app-backend/wallet/services.py`
- URLs: `app-backend/wallet/urls.py`

### Subscriptions
- Models: `app-backend/subscriptions/models.py`
- Views: `app-backend/subscriptions/views.py`
- Services: `app-backend/subscriptions/services.py`
- URLs: `app-backend/subscriptions/urls.py`

### Feedback
- Models: `app-backend/feedback/models.py`
- Views: `app-backend/feedback/views.py`
- URLs: `app-backend/feedback/urls.py`

## 4) Flutter entrypoints
- App bootstrap: `the_app/lib/main.dart`
- Route registry: `the_app/lib/core/routing/routes.dart`
- Route builder: `the_app/lib/core/routing/route_generator.dart`
- API paths: `the_app/lib/core/config/api_config.dart`
- HTTP wrapper: `the_app/lib/core/services/api_service.dart`
- Storage/JWT/lang persistence: `the_app/lib/core/services/storage_service.dart`
- Deep links: `the_app/lib/core/services/deep_link_service.dart`

## 5) App folders that matter most
### Shared infrastructure
- `the_app/lib/core/`
- `the_app/lib/data/`

### Active reusable feature code
- `the_app/lib/features/analytics/`
- `the_app/lib/features/notifications/`

### Most real UI work
- `the_app/lib/presentation/`

Important screen areas
- product: `presentation/product/`
- promotion: `presentation/promotion/`
- pack: `presentation/pack/`
- profile / merchant flows: `presentation/profile/`
- wallet: `presentation/wallet/`
- subscriptions: `presentation/subscription/`
- feedback: `presentation/feedback/`

## 6) Shared app patterns
### Detail-screen pattern
If you edit one of these, inspect the others too:
- `product_detail_screen.dart`
- `promotion_detail_screen.dart`
- `pack_detail_screen.dart`

Related shared widgets
- `presentation/common/widgets/reviews_section.dart`
- `presentation/shared_widgets/report_bottom_sheet.dart`
- `presentation/shared_widgets/contact_action_row.dart`
- `presentation/shared_widgets/qr_payload_dialog.dart`

### Localization pattern
New UI text may need changes in more than one place:
- `the_app/lib/l10n/*.arb`
- `the_app/lib/core/localization/runtime_translations.dart`
- `the_app/lib/core/extensions/l10n_extension.dart`

### Deep-link pattern
If a store/product route changes, inspect:
- backend short links in `app-backend/backend/urls.py`
- app parsing in `the_app/lib/core/services/deep_link_service.dart`
- Android intent filters in
  `the_app/android/app/src/main/AndroidManifest.xml`

## 7) API sync points
If a backend endpoint changes, usually sync all of these:
- backend `urls.py`
- backend `views.py`
- Flutter `api_config.dart`
- the relevant screen/service/provider
- documentation files at repo root

## 8) Trust and moderation map
Trust logic is split across modules:
- models/settings: `users/models.py`
- score computation: `users/trust_scoring.py`
- signal recording: `users/abuse.py`
- product review/report enforcement: `catalog/views.py`
- store report enforcement: `users/views.py`
- client report/review UI:
  - `presentation/shared_widgets/report_bottom_sheet.dart`
  - `presentation/common/widgets/reviews_section.dart`

## 9) Monetization map
Wallet and subscriptions are related but different:

Wallet
- coin balances
- coin packs
- purchase request + admin approval

Subscriptions
- plan catalog
- payment request + proofs
- access status
- merchant dashboard

If a monetization change is requested, inspect both modules before assuming the feature belongs to only one.

## 10) Known gotchas
1. Do not introduce a separate store domain model in the app or backend without a deliberate architecture change.
2. Do not document `go_router` as the active router.
3. Do not assume all text is already in ARB; runtime translations are still part of production behavior.
4. Do not forget that Android is the only retained platform in the repo tree.
5. Device registration currently appears in more than one backend path; the app uses `/api/notifications/devices/`.

## 11) Best companion docs
Read these with this file:
- `API_LINKS_EXPLAINED.txt`
- `APP_LIB_STRUCTURE.txt`
- `SERVER_STRUCTURE.txt`
- `MISSING_NOW_AND_NEXT_ACTIONS.txt`
- `AI_EDITING_GUIDE_FOR_WINO.md`
