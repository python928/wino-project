# PROJECT CONTEXT FOR AI AND MEMOIRE (Wino)

Last updated: 2026-03-23

## 1) Purpose of this file
This file is a compact operational context for:
- AI coding assistants
- university memoire writing
- contributors who need code truth without reading the whole repo

It focuses on what is true now in code, not only on planned features.

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
1. first-run launch screen now includes a visible language picker
2. location/GPS explanation is now centralized in shared helper code
3. nearby/location behavior is more consistent across home/search/edit-profile
4. ads dashboard now includes better explainability text
5. common localization increasingly resolves through ARB/localizations before runtime fallback
6. device registration path was cleaned up to `/api/notifications/devices/`
7. user-facing notification branding now uses `Wino Notifications`

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
- engineering contribution: unified user/store model + modular backend + measurable monetization loop
- UX contribution: onboarding, location education, and merchant explainability improvements
- business contribution: local O2O fit for Algerian market with targeted ads and gradual monetization

## 9) Production-readiness gaps to mention transparently
- security hardening in settings still required
- base URL is still local/hardcoded in app config
- broader tests are needed for OTP, wallet, subscriptions, deep links, and location UX
- observability stack is still incomplete
- some legacy naming remains in package/config values even after branding improvements
