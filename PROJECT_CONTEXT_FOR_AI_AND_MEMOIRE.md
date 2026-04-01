# PROJECT CONTEXT FOR AI AND MEMOIRE (Wino)

Last updated: 2026-04-01

## 1) Purpose of this file
This file is a compact operational context for:
- AI coding assistants
- university memoire writing
- contributors who need code truth without reading the whole repo

It focuses on what is true now in code, not only on planned features.

## 1.5) Unified status truth
Canonical status reference:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`

Current wording rule:
- Wino has a strong implemented technical scope.
- The UI/UX transformation is substantial and real.
- The project is best described as advanced pre-production with a realistic pilot path.
- It should not be described as a fully production-ready commercial release yet.

## 2) Core domain rules
- `Store == User`
- there is no separate Store model
- any endpoint/screen labeled “store” usually uses `users.User` ID
- public-facing brand is `Wino`

## 3) Backend apps and responsibilities
- `users`: auth, profile, phone OTP, followers, store reports, system settings, trust settings
- `catalog`: categories, products, packs, promotions, reviews, favorites, product reports
- `ads`: ad campaigns with targeting and metrics
- `subscriptions`: plans, access status, merchant dashboard, payment requests
- `wallet`: coin balances, coin purchases, admin approval flow
- `analytics`: interaction logs, trust signals, recommendations
- `notifications`: in-app notifications + FCM devices
- `feedback`: user feedback and admin review flow

## 4) Key recent implementation changes
1. first-run launch screen now includes a visible language picker with integrated Locale provider
2. location/GPS explanation is now centralized in shared helper code with unified error dialogs
3. nearby/location behavior is more consistent across home/search/edit-profile
4. ads dashboard now includes better explainability text
5. external Google Maps integration for store directions with GPS fallback and recovery UI
6. multilingual user-facing feedback now covers all 11 core screens:
   - home screen: empty states, snackbar feedback
   - profile/edit screens: follow/unfollow, image uploads, data save feedback
   - product/pack/promotion detail screens: favorite toggles, follow actions, reviews
   - favorites: removed from favorites feedback, error loading state
   - wallet: payment request dialogs, coin purchase feedback
   - notifications & ads dashboard: localized titles and state messages
   - ~60 new FR/AR entries in RuntimeTranslations for fallback safety
7. localization now consistently uses context.tr() + ARB/generated for common strings + RuntimeTranslations fallback for legacy screens
8. device registration path was cleaned up to `/api/notifications/devices/`
9. user-facing notification branding now uses `Wino Notifications`
10. auth onboarding and phone profile setup now share clearer flow primitives through `presentation/auth/widgets/auth_flow_components.dart`
11. category selection is now more context-aware across auth, search, and publishing flows through `presentation/search/category_selection_screen.dart`

## 5) API consistency notes (important)
- App config contains subscription paths including:
  - `/api/subscriptions/plans/`
  - `/api/subscriptions/payment-requests/`
- Backend router currently exposes both:
  - `/api/subscriptions/payment-requests/`
  - `/api/subscriptions/subscription-payment-requests/`
- Merchant dashboard remains under:
  - `/api/subscriptions/merchant-subscriptions/merchant-dashboard/`
- FCM device registration should be documented as:
  - `/api/notifications/devices/`

## 6) Admin panel reality
- “Stores” are managed under Users admin because `Store == User`
- `SystemSettings` and `TrustSettings` live under users-related admin concerns
- category hierarchy is simplified compared to older assumptions in docs

## 7) Flutter architecture cues for contributors
- active routing style: custom `RouteGenerator` + named routes
- `go_router` exists in dependencies but is not the active router
- prefer existing core services/providers/components before adding new patterns
- most real user-facing work still lives in `presentation/`

## 8) Memoire-ready narrative anchors
- academic problem: interpretable local discovery + personalization + trust under practical constraints
- engineering contribution: unified user/store model + modular backend + measurable monetization loop + comprehensive multilingual UX coverage
- UX contribution: onboarding, location education, Google Maps integration, and merchant explainability improvements + full localization across core user journeys
- business contribution: local O2O fit for Algerian market with targeted ads and gradual monetization + multilingual support for broader regional reach

## 9) Production-readiness gaps to mention transparently
- security hardening in settings still required
- base URL is still local/hardcoded in app config
- broader tests are needed for OTP, wallet, subscriptions, deep links, and location UX
- observability stack is still incomplete
- some legacy naming remains in package/config values even after branding improvements

## 2026-03-30 Maps Directions Update
- Location UX now includes external Google Maps directions for store-linked detail pages.
- The implemented pattern is deliberately centralized and Android-oriented: one service, one reusable button, one localized GPS-disabled recovery flow.
- This should be treated as current project context for any future edits touching detail pages or location behavior.

## 2026-03-30 Home Ads Single-Random Update
- Homepage sponsored ads are now a server-ranked, server-filtered, single-result experience rather than a client-rendered multi-item banner feed.
- This improves methodological clarity for the mémoire: preference-aware ranking and random exploration happen on the backend, while Flutter only requests and displays the chosen item.
- Nearby/city changes in the home screen now refresh the sponsored banner request so the server can re-evaluate eligibility.

## 2026-03-30 Dropdowns And Switches Design Update
- The Flutter UI now has an explicit shared visual language for popup menus, form dropdowns, switches, and filter pills instead of one-off per-screen styling.
- The typography decision is now concrete enough to cite in project context: Arabic uses `Alexandria`, while English and French use `Sora`.
- This should be treated as a UI-system invariant for future refinement work, especially in merchant/profile/forms flows.

## 2026-03-30 Search And Profile UI Stability Update
- Search usability now includes explicit first-open category bootstrapping instead of relying on previous navigation history.
- Profile settings consistency was reinforced so merchant-facing action menus stay aligned with the intended owner workflow.
- UI hardening now explicitly accounts for font-driven overflow risk in compact card metadata/badge rows.

## 2026-04-01 Auth And Category Flow Update
- Auth flow quality improved materially: registration and phone profile setup now use a shared screen shell instead of drifting as separate one-off forms.
- Category selection is no longer only a generic picker; it now supports context such as required minimum, maximum selection, contextual helper copy, and tailored confirm labels.
- These changes strengthen both the product narrative and the memoire narrative because they show iterative, evidence-shaped refinement rather than isolated cosmetic edits.

## 2026-04-01 Comprehensive Multilingual User Experience Update
- Localization now covers all 11 core high-traffic screens (100% of primary user journeys) with full English, French, and Arabic support.
- Implementation method: systematic context.tr() wrapping + RuntimeTranslations fallback maps + ARB-generated localizations for common strings.
- Coverage scope: home (4 snackbars + empty state), profile (15+ snackbars/labels), product/pack/promotion details (6 favorite/follow snackbars each), favorites (2 snackbars + error state), wallet (2+ snackbars + dialogs), edit customer/merchant profiles (8-15 snackbars/labels), notifications/ads dashboard (titles and feedback).
- ~60 new FR/AR translation entries added to runtime fallback system to ensure every user-facing feedback message and error state displays localized text.
- Architectural clarity improved: ARB files + generated localization for reusable/common strings + runtime translations as explicit fallback for screens not yet migrated creates a coherent localization story.
- Secondary screens (add product, add promotion, some auth/review flows) remain partial and should be audited in future pass.
- This improvement is significant for the business/UX narrative: Wino now credibly supports multilingual user experiences across the most impactful interactions, addressing a key requirement for regional appeal in Algeria.
