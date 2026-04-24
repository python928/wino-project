# AI Editing Guide For Wino

Last updated: 2026-04-01

This file is meant for AI assistants and programmers who need to edit the repo without rediscovering its rules every time.

## Status reality
Canonical status reference:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`

Do not describe the repo as a finished production release.
The honest wording is:
- strong technical artifact,
- large UI/system progress,
- advanced pre-production / pilot-ready direction.

## 1) Non-negotiable project invariants
1. `Store == User`
2. Flutter uses named routes through `RouteGenerator`
3. Localization is hybrid, not single-source yet
4. The repo is Android-only at platform-folder level
5. Root docs are part of the project knowledge base and should be kept in sync with architectural changes
6. Public-facing brand is `Wino`

## 2) What to inspect before editing by topic
### Auth / onboarding / category selection
- `wino_app/lib/presentation/auth/register_screen.dart`
- `wino_app/lib/presentation/auth/phone_profile_setup_screen.dart`
- `wino_app/lib/presentation/auth/widgets/auth_flow_components.dart`
- `wino_app/lib/presentation/search/category_selection_screen.dart`
- `wino_app/lib/core/widgets/app_text_field.dart`

### Auth / profile / store
- `wino_backend/users/models.py`
- `wino_backend/users/views.py`
- `wino_backend/users/serializers.py`
- `wino_app/lib/presentation/profile/`
- `wino_app/lib/core/services/storage_service.dart`

### Products / promotions / packs
- `wino_backend/catalog/models.py`
- `wino_backend/catalog/views.py`
- `wino_app/lib/presentation/product/product_detail_screen.dart`
- `wino_app/lib/presentation/promotion/promotion_detail_screen.dart`
- `wino_app/lib/presentation/pack/pack_detail_screen.dart`

### Reviews / reports / trust
- `wino_backend/catalog/views.py`
- `wino_backend/users/views.py`
- `wino_backend/users/trust_scoring.py`
- `wino_app/lib/presentation/common/widgets/reviews_section.dart`
- `wino_app/lib/presentation/shared_widgets/report_bottom_sheet.dart`

### Wallet / subscriptions / merchant growth
- `wino_backend/wallet/`
- `wino_backend/subscriptions/`
- `wino_backend/ads/`
- `wino_app/lib/presentation/wallet/`
- `wino_app/lib/presentation/subscription/`
- `wino_app/lib/core/config/api_config.dart`

### Deep links / sharing / QR
- `wino_backend/backend/urls.py`
- `wino_app/lib/core/services/deep_link_service.dart`
- `wino_app/android/app/src/main/AndroidManifest.xml`
- `wino_app/lib/presentation/shared_widgets/qr_payload_dialog.dart`

### Localization
- `wino_app/lib/l10n/*.arb` (generated translations)
- `wino_app/lib/core/localization/runtime_translations.dart` (FR/AR fallback)
- `wino_app/lib/core/extensions/l10n_extension.dart` (context.tr() helper)
- Implementation rule: wrap all user-visible text in `context.tr()`, add FR/AR entries to RuntimeTranslations if not in ARB files
- Current status: 11 core screens are 100% localized; secondary screens remain partial

### Nearby / location UX
- `wino_app/lib/presentation/common/location_permission_helper.dart`
- `wino_app/lib/presentation/home/home_screen.dart`
- `wino_app/lib/presentation/search/search_tab_screen.dart`
- `wino_app/lib/presentation/profile/edit_merchant_profile_screen.dart`

### External Maps / directions
- `wino_app/lib/core/services/external_maps_service.dart` (Google Maps integration)
- `wino_app/lib/presentation/shared_widgets/directions_button.dart` (reusable directions button)
- Used in: product_detail, promotion_detail, pack_detail, profile (store view)
- Recovery pattern: GPS-disabled → user prompted to enable in settings (do not repeat GPS logic per-screen)

## 3) Change propagation rules
### If you change a backend endpoint
Also check:
- backend router/url file
- backend view/serializer
- `wino_app/lib/core/config/api_config.dart`
- the calling service/screen/provider
- `API_LINKS_EXPLAINED.txt`

### If you change product detail behavior
Also inspect:
- promotion detail screen
- pack detail screen
- reviews section
- report bottom sheet
- runtime translations / ARB strings

### If you add or rename UI text
Workflow:
1. Wrap in `context.tr('Your English text')`
2. If it's a reusable/common string, add to `l10n/en.arb`
3. Run `flutter gen-l10n` to generate localizations
4. Add FR/AR translations to `runtime_translations.dart` for fallback safety
5. Test in EN/FR/AR to confirm display

Current state: all snackbars, dialogs, labels, and feedback messages in core screens already follow this pattern.

### If you change trust/report/review rules
Also update:
- docs describing trust and moderation
- any related app-side snackbars, labels, and report reasons

### If you change branding-visible text
Also inspect:
- app constants/config
- local notification channel naming
- onboarding copy
- docs that still mention older product names

## 4) Current architecture realities that are easy to get wrong
1. `go_router` is installed but not active.
2. Some list endpoints return paginated data; some code still tolerates direct lists.
3. Device registration should be treated as `/api/notifications/devices/`.
4. Product/store trust logic spans both `users/` and `catalog/`.
5. Most actual Flutter feature work still lives in `presentation/`, even though `features/` exists.
6. Some internal names still use legacy values such as `wino`, but visible branding is `Wino`.

## 5) Safe mental model for the app
- `core/` = infrastructure
- `data/` = models/repositories
- `features/` = reusable logic where present
- `presentation/` = most real UI and user flows

If you are unsure where a user-facing behavior lives, check `presentation/` first.

## 6) Good doc set to load before big work
Recommended order:
1. `PROJECT_DOCUMENTATION_INDEX.md`
2. `CODEBASE_MAP_FOR_AI.md`
3. `API_LINKS_EXPLAINED.txt`
4. `APP_LIB_STRUCTURE.txt`
5. `SERVER_STRUCTURE.txt`
6. `MISSING_NOW_AND_NEXT_ACTIONS.txt`
7. `PROJECT_CONTEXT_FOR_AI_AND_MEMOIRE.md`

## 7) Prompt context that helps an AI assistant
Useful facts to include in prompts:
- `Store == User`
- `Android-only Flutter repo`
- `Named routes via RouteGenerator`
- `Hybrid localization: ARB + runtime_translations (11 core screens 100% multilingual)`
- `External Google Maps integration via ExternalMapsService + DirectionsButton`
- `Trust layer exists for reports/reviews`
- `Wallet + subscriptions + ads are all active product areas`
- `Docs at repo root should be updated when architecture changes`
- `Visible brand is Wino`
- `All user-facing feedback requires context.tr() + FR/AR translation entries`

## 8) What counts as a good change in this repo
A good change usually does all of the following:
- respects the existing domain model
- updates the shared UI pattern, not only one isolated screen
- keeps app and backend contracts aligned
- updates user-visible text correctly
- leaves the docs slightly better than they were
