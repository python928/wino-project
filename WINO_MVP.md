# Wino Minimum Viable Product (MVP)

Last updated: 2026-04-01

## 0) Current stage note
Canonical status reference:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`

Important wording rule:
- this file defines the honest target shape of the MVP,
- it does not mean Wino has already earned an MVP release label,
- and it definitely should not be used as proof that the product is already production-ready.

## 1) MVP Goal
The MVP should be the smallest release that proves Wino can help Algerian users discover nearby offers they trust, while giving merchants a lightweight way to publish and promote inventory.

This MVP should optimize for:
- local usefulness,
- operational simplicity,
- trust,
- measurable merchant activation.

It should not optimize first for nationwide scale or fully automated commerce.

## 2) MVP User Promise
For users:
- find nearby products, packs, and promotions,
- evaluate trust cues before contacting a merchant,
- save, share, and revisit relevant offers.

For merchants:
- create a local storefront through the unified user profile,
- publish offers quickly,
- understand basic performance and promotion options,
- start growth without enterprise tooling.

## 3) Core MVP Scope
### Must-have user flows
- onboarding with visible language selection,
- account registration/login,
- home feed and search,
- nearby and location-aware discovery,
- external map directions from store-linked detail views (product, pack, promotion, store),
- store, product, pack, and promotion detail views,
- favorites,
- reviews and reporting,
- direct contact/share/QR/deep-link pathways,
- feedback submission.

### Must-have merchant flows
- merchant profile setup,
- location/contact/profile editing,
- product publishing,
- promotion publishing,
- pack publishing,
- basic merchant-facing dashboard or performance summary where already available.

### Must-have platform/admin flows
- moderation of reports and reviews,
- notification delivery setup,
- catalog and user administration,
- support for pilot feedback and issue handling.

## 4) MVP Features That Should Stay Pilot-Only
These can exist in the product, but should be rolled out carefully at first:
- ads campaigns,
- subscription payment requests,
- wallet purchase approval flows,
- advanced recommendation tuning,
- broad merchant monetization.

Reason:
- these flows already exist,
- but they still depend on manual review, explainability improvements, and release hardening.

## 5) What Is Explicitly Out Of MVP Scope
- iOS, web, and desktop clients,
- fully automated online payment and fulfillment,
- national-scale merchant acquisition,
- advanced ROI analytics for all merchants,
- mature A/B experimentation stack,
- full production observability maturity,
- perfect localization coverage across every screen.

Keeping these out of the MVP is a strength, not a weakness. It keeps the launch honest.

## 6) Recommended MVP Release Shape
The cleanest MVP is:
- Android-first,
- one or a few pilot geographies,
- curated merchant onboarding,
- manual operational support where needed,
- public user discovery with limited merchant admission.

That shape fits both the code reality and the Algerian local-commerce context.

## 7) MVP KPI Set
### User KPIs
- activated users,
- weekly active users,
- search-to-detail conversion,
- detail-to-contact/share/favorite conversion,
- return rate after first meaningful session.

### Merchant KPIs
- merchants onboarded,
- time to first listing,
- listings per merchant,
- repeat publishing rate,
- merchant retention after 30 and 90 days.

### Trust KPIs
- report rate per active listing,
- moderation response time,
- low-credibility review/report ratio,
- user perception of trust in pilot surveys.

### Operational KPIs
- crash/error rate,
- notification reliability,
- support ticket volume,
- payment-review turnaround time for monetization pilots.

## 8) Release Readiness Checklist
Before calling Wino an MVP release, these items should be complete:

### Critical
- move `baseUrl` and related app config to environment-aware values,
- harden server production settings,
- reduce or remove cleartext-only assumptions,
- validate auth/OTP behavior for release conditions,
- confirm FCM device registration and notification reliability.

### Very important
- expand localization coverage on all core flows,
- add targeted test coverage for auth, reports/reviews, subscriptions, wallet, deep links, and nearby flows,
- prepare release checklist and operational fallback paths,
- clean remaining visible branding inconsistencies.

## 9) MVP Roadmap Recommendation
### Phase 1: Launch-ready core
- nearby discovery,
- publishing,
- trust/reporting,
- share/contact flows,
- feedback loop.

### Phase 2: Merchant confidence
- better explainability in dashboard views,
- clearer lifecycle messaging for payment and subscription events,
- stronger merchant notifications.

### Phase 3: Monetization scale-up
- gradual rollout of paid plans,
- controlled ads expansion,
- better campaign reporting and ROI storytelling.

## 10) Web-Backed Market Signal
The MVP thesis is supported by recent market signals:
- Algeria's internet penetration reached about 79.5% based on late-2025 data reported by DataReportal.
- SATIM reports a growing electronic payment base, including 51,000+ terminals and 500+ active web merchants.
- APS reported official support for further e-commerce facilitation with digital security safeguards on 2025-12-14.

These signals do not guarantee adoption, but they support a realistic MVP launch hypothesis.

## 11) Sources
- DataReportal, Digital 2026: Algeria: https://datareportal.com/reports/digital-2026-algeria
- SATIM, Qui sommes nous: https://www.satim.dz/index.php/fr/satim/qui-sommes-nous
- APS, e-commerce facilitation and digital security, 2025-12-14: https://www.aps.dz/fr/presidence-news/mj65b5vk-le-president-de-la-republique-affirme-la-necessite-d-accorder-davantage-de-facilitations
