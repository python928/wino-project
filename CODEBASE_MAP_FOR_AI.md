# CODEBASE MAP FOR AI ASSISTANTS AND NEW CONTRIBUTORS

Last updated: 2026-04-01

This file is the shortest reliable map of where to go first in the Wino codebase.

Current stage note
- Treat the repo as a strong implemented platform in advanced pre-production.
- Do not let older “production ready” wording override the current status reference in `TRANSFORMATION_COMPLETE_SUMMARY.md`.

## 1) First truths to keep in mind
- `Store == User`
- Backend is Django/DRF
- App is Flutter Android-first
- Active app routing is `RouteGenerator`, not `go_router`
- Localization is implemented through:
  - generated ARB localizations (arabic, french, english)
  - `runtime_translations.dart` with FR/AR fallback maps for legacy screens
  - context.tr() extension method as primary UI translation handler
  - all core user-facing screens (11+ primary flows) now support full multilingual feedback
- External Maps integration uses Google Maps for directions via `ExternalMapsService` with GPS fallback handling
- Public-facing brand is `Wino`, even though some internal identifiers still use legacy names

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
- daily / first-login coin policies

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
- onboarding / launch: `presentation/auth/`
- home / nearby: `presentation/home/`
- search / filters: `presentation/search/`
- product: `presentation/product/`
- promotion: `presentation/promotion/`
- pack: `presentation/pack/`
- profile / merchant flows: `presentation/profile/`
- subscriptions: `presentation/subscription/`
- wallet: `presentation/wallet/`
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
- `presentation/shared_widgets/directions_button.dart`

### Auth-flow pattern
If you edit registration or phone profile setup, inspect:
- `the_app/lib/presentation/auth/register_screen.dart`
- `the_app/lib/presentation/auth/phone_profile_setup_screen.dart`
- `the_app/lib/presentation/auth/widgets/auth_flow_components.dart`
- `the_app/lib/core/widgets/app_text_field.dart`

### Category-selection pattern
If you change interests/categories UX, inspect:
- `the_app/lib/presentation/search/category_selection_screen.dart`
- `the_app/lib/presentation/search/search_tab_screen.dart`
- `the_app/lib/presentation/profile/add_product_screen.dart`
- `the_app/lib/presentation/auth/register_screen.dart`
- `the_app/lib/presentation/auth/phone_profile_setup_screen.dart`

### Localization pattern
New UI text may need changes in more than one place:
- `the_app/lib/l10n/*.arb` (English, French, Arabic)
- `the_app/lib/core/localization/runtime_translations.dart` (FR/AR fallback for ungenerated strings)
- `the_app/lib/core/extensions/l10n_extension.dart` (context.tr() helper)

Implementation rule for new strings
- Wrap all user-facing text in `context.tr('English text')`
- If the key exists in ARB files, the generated localization system handles it
- If not, the runtime_translations._fr/_ar maps provide fallback (add entries there)
- All 11 core screens now follow this pattern; maintain consistency when adding new screens

Current localization status
- Core user journeys: ~100% coverage (home, profile, product/pack/promotion details, favorites, wallet, notification, dashboard, settings)
- Secondary screens: partial (add product, add promotion, some auth/review flows)
- All snackbars, dialogs, error states, and feedback paths support EN/FR/AR

### External Maps integration pattern
GPS direction support is implemented as an external service:
- Service layer: `the_app/lib/core/services/external_maps_service.dart`
- Reusable widget: `the_app/lib/presentation/shared_widgets/directions_button.dart`
- Used in: product_detail, promotion_detail, pack_detail, profile (store view)

Fallback behavior
- If GPS is disabled: button prompts to enable in settings (localized string)
- If Maps app is not installed: fallback to intent with coordinates
- If coordinates are missing: button is hidden or disabled gracefully

Do not repeat GPS logic in individual screens; always route through ExternalMapsService and DirectionsButton widget.

### Nearby / location UX pattern
If nearby or GPS behavior changes, inspect:
- `presentation/common/location_permission_helper.dart`
- `presentation/home/home_screen.dart`
- `presentation/search/search_tab_screen.dart`
- `presentation/profile/edit_merchant_profile_screen.dart`
- `presentation/shared_widgets/unified_app_bar.dart`

### Deep-link pattern
If a store/product route changes, inspect:
- backend short links in `app-backend/backend/urls.py`
- app parsing in `the_app/lib/core/services/deep_link_service.dart`
- Android intent filters in `the_app/android/app/src/main/AndroidManifest.xml`

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
Wallet and subscriptions are related but different.

Wallet
- coin balances
- coin packs
- purchase request + admin approval

Subscriptions
- plan catalog
- payment request + proofs
- access status
- merchant dashboard

Ads
- campaign creation
- click registration
- dashboard / performance interpretation

If a monetization change is requested, inspect all three before assuming the feature belongs to only one.

## 10) Known gotchas
1. Do not introduce a separate store domain model in the app or backend without a deliberate architecture change.
2. Do not document `go_router` as the active router.
3. Do not assume all text is already in ARB; runtime translations are still part of production behavior.
4. Do not forget that Android is the only retained platform in the repo tree.
5. Device registration is now documented and used through `/api/notifications/devices/`.
6. User-facing brand is `Wino`, but some internal names still use legacy identifiers.

## 11) Best companion docs
Read these with this file:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`
- `PROJECT_DOCUMENTATION_INDEX.md`
- `API_LINKS_EXPLAINED.txt`
- `APP_LIB_STRUCTURE.txt`
- `SERVER_STRUCTURE.txt`
- `MISSING_NOW_AND_NEXT_ACTIONS.txt`
- `AI_EDITING_GUIDE_FOR_WINO.md`
- `MEMOIRE_RESEARCH_DOSSIER_2026-03.md` if the task touches university writing

## 2026-03-30 Maps Directions Update
- New service node: `the_app/lib/core/services/external_maps_service.dart`
- New shared widget node: `the_app/lib/presentation/shared_widgets/directions_button.dart`
- Updated screen nodes: product detail, promotion detail, pack detail, and store/profile flows now share one external-maps pattern with localized GPS-disabled recovery.

## 2026-03-30 Home Ads Single-Random Update
- Backend selection node: `app-backend/ads/views.py`
- Backend verification node: `app-backend/ads/tests.py`
- Flutter request/render nodes: `the_app/lib/core/providers/post_provider.dart`, `the_app/lib/data/repositories/post_repository.dart`, `the_app/lib/presentation/home/home_screen.dart`

## 2026-03-30 Dropdowns And Switches Design Update
- Typography node: `the_app/lib/core/theme/app_typography.dart`
- Shared menu node: `the_app/lib/presentation/shared_widgets/app_dropdown_menu.dart`
- Shared switch node: `the_app/lib/presentation/shared_widgets/app_switch_tile.dart`
- Shared filter-chip node updated: `the_app/lib/core/widgets/app_toggle_button.dart`

## 2026-03-30 Search And Profile UI Stability Update
- Search bootstrap node: `the_app/lib/presentation/search/search_tab_screen.dart`
- Profile settings action reuse nodes: `the_app/lib/presentation/profile/profile_screen.dart`, `the_app/lib/presentation/profile/widgets/profile_merchant_header.dart`
- Shared card overflow-hardening nodes: `the_app/lib/core/widgets/cards/base_item_card.dart`, `the_app/lib/presentation/shared_widgets/cards/promotion_card.dart`, `the_app/lib/presentation/shared_widgets/cards/store_chip.dart`

## 2026-04-01 Auth And Category Flow Update
- Shared auth flow node: `the_app/lib/presentation/auth/widgets/auth_flow_components.dart`
- Updated auth screen nodes: `the_app/lib/presentation/auth/register_screen.dart`, `the_app/lib/presentation/auth/phone_profile_setup_screen.dart`
- Shared category-selection node: `the_app/lib/presentation/search/category_selection_screen.dart`
- Supporting input/system node: `the_app/lib/core/widgets/app_text_field.dart`
