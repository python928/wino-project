# Project Organization Audit (2026-03-07)

## Applied in this refactor
- Reduced repeated UI state blocks in `HomeScreen` by centralizing:
  - compact error state builder
  - compact empty state builder
- Reduced repeated feed-loading calls by adding:
  - `PostProvider.refreshMarketplaceFeed()`
  - reused from Home and MainNavigation.
- Reduced repeated provider boilerplate in `HomeProvider`:
  - central `_runSectionLoad()` wrapper for loading/error/notify lifecycle.
- Reduced repeated backend logic in `catalog/views.py`:
  - central `_trigger_new_post_notification()` for product/pack/promotion creation.

## Current structural risks
- `HomeScreen` is still large (many responsibilities in one file).
- `SearchTabScreen` and profile screens likely have similar UI-state duplication patterns.
- Data-loading orchestration is spread across screens/providers with partial overlap.
- Recommendation-aware ranking logic exists in multiple layers (server + app), needs clear boundary docs.

## Recommended next refactor wave
1. Split `HomeScreen` into section widgets:
   - `home_sections/offers_section.dart`
   - `home_sections/products_section.dart`
   - `home_sections/packs_section.dart`
   - `home_sections/stores_section.dart`
2. Create shared async-state widgets:
   - one reusable section state component for loading/error/empty.
3. Move ranking/adaptation logic to dedicated service:
   - e.g. `lib/core/services/offers_ranking_service.dart`.
4. Introduce lightweight architecture guardrails:
   - feature-based folder contracts
   - one orchestrator per screen feature
   - avoid direct API calls inside UI widgets.

## Backend future-proofing recommendations
1. Move complex promotion impression logic to `catalog/services/promotion_service.py`.
2. Add tests for:
   - `PromotionViewSet._register_impressions`
   - plan constraints (`max_active`, `max_duration`, `max_impressions`).
3. Add application-level logging (structured) for recommendation and promotion decisions.
