# Wino Current Project Status and Transformation Summary

Last updated: 2026-04-01

This document is now the canonical status reference for the repository.

If another document sounds more optimistic or more pessimistic than this one, treat this file as the source of truth and update the other document.

## 1) The honest short version
Wino is no longer a sketch, a click-through demo, or a toy marketplace. It is a serious Android-first technical product with real backend breadth, real Flutter flows, meaningful UI/UX improvements, and real local-commerce logic.

But honesty matters:

Wino should currently be described as an **advanced pre-production, pilot-ready technical platform**, not as a fully production-ready commercial release.

## 2) Unified status matrix
- `UI/UX transformation`: largely completed and materially stronger than before
- `Technical POC`: achieved
- `Product POC`: advanced, but still only partially validated in the field
- `MVP release`: being assembled and hardened
- `Pilot readiness`: realistic after release-critical hardening
- `Full production readiness`: not yet honestly earned

## 3) Why the old wording became misleading
Some earlier UI documents used phrases such as:
- `Transformation Complete`
- `Production Ready`
- `world-class`

Those phrases captured a real truth about the scale of the UI work, but they blurred an important distinction:
- the **UI/component foundation** became much stronger,
- while the **overall product/release posture** still has hardening gaps.

The contradiction was not that the improvements were fake. The contradiction was that the scope of the claim became too wide.

## 4) What is genuinely strong now
### Product and architecture
- Django + DRF backend with modular apps for users, catalog, ads, subscriptions, wallet, analytics, notifications, and feedback
- Flutter Android client with named-route navigation and real multi-screen product flows
- `Store == User` remains a coherent simplifying domain rule
- multilingual groundwork is active across Arabic, French, and English

### Discovery, trust, and merchant flows
- nearby discovery and area-aware filtering are implemented
- reviews, reports, moderation signals, and trust-oriented flows exist in real code
- merchant publishing exists for products, packs, and promotions
- ads, wallet, subscriptions, and payment-proof workflows already exist

### Recent UX/system improvements that changed the codebase materially
- visible first-run language selection with integrated Locale provider
- unified location-permission education and recovery flows across home, search, and merchant-profile screens
- reusable external Google Maps directions with fallback recovery paths through:
  - `wino_app/lib/core/services/external_maps_service.dart`
  - `wino_app/lib/presentation/shared_widgets/directions_button.dart`
  - recovers to settings launch when Maps is unavailable or GPS disabled
- comprehensive multilingual coverage (English, French, Arabic) across core user journeys:
  - 11 high-traffic screens localized via `context.tr()` and RuntimeTranslations fallback system
  - ~60 new FR/AR translation entries added for snackbars, dialogs, error states, and feedback paths
  - ARB-generated localizations + runtime fallback maps for screens not yet migrated
  - all user-facing status messages (favorite toggles, follow actions, review submissions, image uploads, payment requests) now display localized feedback
- shared auth flow primitives through:
  - `wino_app/lib/presentation/auth/widgets/auth_flow_components.dart`
- stronger auth/profile-setup UX in:
  - `wino_app/lib/presentation/auth/register_screen.dart`
  - `wino_app/lib/presentation/auth/phone_profile_setup_screen.dart`
- context-aware category selection reused across auth, search, and publishing in:
  - `wino_app/lib/presentation/search/category_selection_screen.dart`
- clearer shared dropdown/switch patterns in:
  - `wino_app/lib/presentation/shared_widgets/app_dropdown_menu.dart`
  - `wino_app/lib/presentation/shared_widgets/app_switch_tile.dart`
- stronger typography/system consistency through:
  - `wino_app/lib/core/theme/app_typography.dart`

## 5) What still blocks a full production-ready claim
These are not cosmetic gaps. They are release-truth gaps:

- app `baseUrl` is still hardcoded locally in `wino_app/lib/core/config/api_config.dart`
- some server defaults are still too development-friendly
- Android cleartext assumptions still need tightening
- OTP still needs stronger production hardening
- observability, alerting, and runbooks are not yet complete
- end-to-end validation is still too limited for an honest production claim
- Flutter automated coverage is still light relative to the size of the surface area
- localization coverage is now strong across all core user-facing screens (11 primary flows), but secondary and edge-case screens still need audit and migration to RuntimeTranslations

## 6) What should be said from now on
Use wording close to this:

`Wino is an advanced pre-production, Android-first local-commerce platform with a strong implemented technical scope, a largely completed UI/UX transformation, and a realistic path to pilot deployment once release hardening is finished.`

Avoid wording like this unless the scope is made explicit:
- `production ready`
- `transformation complete` with no qualifier
- `ready for launch` with no mention of hardening gaps

If you need a shorter label, use:
- `advanced pre-production`
- `pilot-ready direction`
- `technical POC achieved`

## 7) What changed in documentation policy
From now on:
- `TRANSFORMATION_COMPLETE_SUMMARY.md` means the status of the whole project, not only the UI layer
- UI docs may describe the component system as strong or largely complete, but they should not silently escalate that to whole-product production readiness
- MVP, POC, business, memoire, and engineering docs should all use the same stage language

## 8) Practical reading guide
If you want the truth in the right order, read:
1. `TRANSFORMATION_COMPLETE_SUMMARY.md`
2. `MISSING_NOW_AND_NEXT_ACTIONS.txt`
3. `WINO_POC.md`
4. `WINO_MVP.md`
5. `PROJECT_CONTEXT_FOR_AI_AND_MEMOIRE.md`
6. `CODEBASE_MAP_FOR_AI.md`

## 9) External references that support this wording
These sources help keep the terminology and UX claims grounded:

- Atlassian on the difference between MVP and PoC:
  https://www.atlassian.com/agile/product-management/minimum-viable-product
- W3C WAI forms guidance, including short forms, validation, and multi-step flows:
  https://www.w3.org/WAI/tutorials/forms/
- Android Developers on requesting location permissions:
  https://developer.android.com/training/location/permissions
- Android Developers on common intents for app handoff patterns:
  https://developer.android.com/guide/components/intents-common
- DataReportal, Digital 2026: Algeria:
  https://datareportal.com/reports/digital-2026-algeria
- SATIM corporate/payment ecosystem context:
  https://www.satim.dz/index.php/fr/satim/qui-sommes-nous
- APS, e-commerce facilitation and digital security, 2025-12-14:
  https://www.aps.dz/fr/presidence-news/mj65b5vk-le-president-de-la-republique-affirme-la-necessite-d-accorder-davantage-de-facilitations

## 10) Final wording rule
The strong claim is still justified, but it must be the right strong claim:

Wino is already a substantial and credible product artifact.
Wino is not yet a finished production release.

That distinction makes the documentation stronger, not weaker.
