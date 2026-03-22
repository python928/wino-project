# PROJECT CONTEXT FOR AI AND MEMOIRE (Wino)

Last updated: 2026-03-23

## 1) Purpose of this file
This file is a compact operational context for:
- AI coding assistants (faster accurate code changes)
- University memoire writing (clear architecture + implementation reality)

It focuses on what is true now in code, not planned features.

## 2) Core domain rules
- Store == User.
- There is no separate Store model.
- Any endpoint/screen labeled "store" usually uses `users.User` ID.

## 3) Backend apps and responsibilities
- `users`: auth, profile, phone OTP, followers, store reports, system settings.
- `catalog`: categories, products, packs, promotions, reviews, favorites, product reports.
- `ads`: ad campaigns with audience/geo targeting and metrics.
- `subscriptions`: merchant subscription status/dashboard.
- `wallet`: coin balances, coin purchases, admin approval flow.
- `analytics`: interaction logs, preference profiles, recommendations.
- `notifications`: in-app notifications + FCM devices.

## 4) Key recent implementation changes
1. Daily coin top-up system:
   - Triggered via `GET /api/users/me/`.
   - Uses `users.SystemSettings.daily_login_coins`.
   - Applies only if 24h passed and user balance is below target.
2. First-login coin grant is server-configurable:
   - `users.SystemSettings.first_login_coins`.
3. Category parent is hidden from admin and no longer returned in Category API serializer.
4. Ads and Wallet are now independent first-class modules.
5. CI exists in `.github/workflows/ci.yml`.

## 5) API consistency notes (important)
- App config contains subscription paths like:
  - `/api/subscriptions/plans/`
  - `/api/subscriptions/payment-requests/`
- Current router in `subscriptions/urls.py` exposes only:
  - `/api/subscriptions/merchant-subscriptions/` (+ custom actions)

Action: align router and app config before production release.

## 6) Admin panel reality
- "Stores" are managed under Users admin.
- `SystemSettings` appears in Users admin as singleton settings.
- Category admin add form does not require parent.

## 7) Flutter architecture cues for contributors
- Active routing style: custom `RouteGenerator` + named routes.
- `go_router` exists in dependencies but is not the active router.
- Prefer existing core services/providers/components before adding new patterns.

## 8) Memoire-ready narrative anchors
- Academic problem: interpretable local discovery + personalization under practical constraints.
- Engineering contribution: unified user/store model + modular backend + measurable monetization loop.
- Business contribution: local O2O fit for Algerian market with targeted ads and coin economy.

## 9) Production-readiness gaps to mention transparently
- Security hardening in settings still required (`DEBUG`, `ALLOWED_HOSTS`, `CORS`, `SECRET_KEY`).
- Broader tests needed for OTP, wallet approval, ad delivery/click flows, subscription route alignment.
- Observability stack (error tracking/APM) still pending.
