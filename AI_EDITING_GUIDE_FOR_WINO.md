# AI Editing Guide For Wino

Last updated: 2026-03-23

This file is meant for AI assistants and programmers who need to edit the repo without rediscovering its rules every time.

## 1) Non-negotiable project invariants
1. `Store == User`
2. Flutter uses named routes through `RouteGenerator`
3. Localization is hybrid, not single-source yet
4. The repo is Android-only at platform-folder level
5. Root docs are part of the project knowledge base and should be kept in sync with architectural changes

## 2) What to inspect before editing by topic
### Auth / profile / store
- `app-backend/users/models.py`
- `app-backend/users/views.py`
- `app-backend/users/serializers.py`
- `the_app/lib/presentation/profile/`
- `the_app/lib/core/services/storage_service.dart`

### Products / promotions / packs
- `app-backend/catalog/models.py`
- `app-backend/catalog/views.py`
- `the_app/lib/presentation/product/product_detail_screen.dart`
- `the_app/lib/presentation/promotion/promotion_detail_screen.dart`
- `the_app/lib/presentation/pack/pack_detail_screen.dart`

### Reviews / reports / trust
- `app-backend/catalog/views.py`
- `app-backend/users/views.py`
- `app-backend/users/trust_scoring.py`
- `the_app/lib/presentation/common/widgets/reviews_section.dart`
- `the_app/lib/presentation/shared_widgets/report_bottom_sheet.dart`

### Wallet / subscriptions / merchant growth
- `app-backend/wallet/`
- `app-backend/subscriptions/`
- `the_app/lib/presentation/wallet/`
- `the_app/lib/presentation/subscription/`
- `the_app/lib/core/config/api_config.dart`

### Deep links / sharing / QR
- `app-backend/backend/urls.py`
- `the_app/lib/core/services/deep_link_service.dart`
- `the_app/android/app/src/main/AndroidManifest.xml`
- `the_app/lib/presentation/shared_widgets/qr_payload_dialog.dart`

### Localization
- `the_app/lib/l10n/*.arb`
- `the_app/lib/core/localization/runtime_translations.dart`
- `the_app/lib/core/extensions/l10n_extension.dart`

## 3) Change propagation rules
### If you change a backend endpoint
Also check:
- backend router/url file
- backend view/serializer
- `the_app/lib/core/config/api_config.dart`
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
Decide whether it belongs in:
- generated localization (`l10n/*.arb`)
- runtime translations (`runtime_translations.dart`)
- or both during migration

### If you change trust/report/review rules
Also update:
- docs describing trust and moderation
- any related app-side snackbars, labels, and report reasons

## 4) Current architecture realities that are easy to get wrong
1. `go_router` is installed but not active.
2. Some list endpoints return paginated data, some code still tolerates direct lists.
3. Device registration exists at more than one backend path.
4. Product/store trust logic spans both `users/` and `catalog/`.
5. Most actual Flutter feature work still lives in `presentation/`, even though `features/` exists.

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

## 7) Prompt context that helps an AI assistant
Useful facts to include in prompts:
- "Store == User"
- "Android-only Flutter repo"
- "Named routes via RouteGenerator"
- "Hybrid localization: ARB + runtime_translations"
- "Trust layer exists for reports/reviews"
- "Wallet + subscriptions + ads are all active product areas"
- "Docs at repo root should be updated when architecture changes"

## 8) What counts as a good change in this repo
A good change usually does all of the following:
- respects the existing domain model
- updates the shared UI pattern, not only one isolated screen
- keeps app and backend contracts aligned
- updates user-visible text correctly
- leaves the docs slightly better than they were
