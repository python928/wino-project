# Wino Proof of Concept (POC)

Last updated: 2026-04-01

## 0) Current stage note
Canonical status reference:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`

This document should be read with one discipline:
- strong technical POC does not automatically mean production-ready product.
- Wino is best described today as an advanced pre-production platform with a credible pilot path.

## 1) Purpose
This document defines the Proof of Concept for Wino as it exists now in code and as it should be validated in a controlled field pilot.

The core POC question is:

Can an Algeria-focused, Android-first local commerce platform combine nearby discovery, trust signals, and lightweight merchant growth tools in one coherent product without requiring fully mature payment and logistics infrastructure?

## 2) What Wino Already Proves Technically
The current repository already proves more than a mockup or click-through demo.

Implemented proof points include:
- a working Django + DRF backend with modular apps,
- a Flutter Android-first client,
- nearby and search-oriented discovery flows,
- product, pack, and promotion publishing,
- reviews, favorites, and reporting flows,
- trust and moderation primitives,
- ads, subscriptions, wallet, and payment-proof workflows,
- analytics and recommendation infrastructure,
- notification and deep-link support,
- multilingual groundwork with Arabic, French, and English support.

In practical terms, the codebase already demonstrates that Wino is a real technical artifact, not only a concept deck.

## 3) What The POC Must Validate
The POC should validate four hypotheses.

### Hypothesis 1: Local discovery is more useful than generic listing
Users in Algeria will perceive better relevance when results reflect nearby distance, wilaya/baladiya context, and merchant location clarity.

### Hypothesis 2: Trust signals improve willingness to interact
Visible reviews, reports, verification cues, and moderation features will increase user confidence compared with unstructured listing channels.

### Hypothesis 3: Small merchants can adopt lighter tooling
Merchants can publish products and promotions, manage profile/location data, and understand basic performance signals without requiring complex dashboards or full e-commerce operations.

### Hypothesis 4: Gradual monetization is viable
Coins, ads, and subscriptions can be introduced in a staged way without blocking early merchant adoption.

## 4) Recommended POC Scope
The POC should stay focused on one narrow operating context rather than trying to prove national scale too early.

Recommended controlled scope:
- one city or one wilaya cluster,
- Android only,
- selected merchants rather than open public onboarding,
- manual operational review where needed,
- short pilot duration with measurable funnel tracking.

Suggested actor groups:
- end users searching for nearby stores and products,
- small or medium merchants publishing offers,
- admin/operators handling moderation and payment-review workflows.

## 5) What To Use From The Current Product
The best POC path is to use current strengths instead of forcing unfinished production features.

Use now:
- onboarding with visible language choice,
- home, nearby, and search flows,
- store/product/promotion/pack detail screens,
- external map directions from detail screens to merchant locations,
- reviews, favorites, and reports,
- merchant publishing and profile editing,
- share, QR, and deep-link flows,
- feedback collection,
- merchant dashboard explainability where already present.

Use only in controlled pilot mode:
- subscription payment requests,
- wallet purchases and approvals,
- ads campaigns and dashboard metrics.

Do not treat as POC requirements:
- full automated checkout,
- nationwide launch,
- iOS/web parity,
- fully mature observability stack.

## 6) POC Success Criteria
The POC should be evaluated with simple, decision-ready metrics.

### User-side
- search or nearby sessions that lead to a detail view,
- detail views that lead to contact, share, favorite, or follow,
- repeat visits within 7 and 30 days,
- report rate and report quality,
- perceived trust and relevance from lightweight interviews or forms.

### Merchant-side
- time to first published listing,
- number of merchants who publish more than once,
- number of merchants who create at least one promotion,
- comprehension of merchant dashboard indicators,
- willingness to continue after the pilot.

### Operational-side
- moderation turnaround time,
- payment-review turnaround time for controlled monetization pilots,
- notification delivery reliability,
- low-severity bug rate during the pilot.

## 7) Current POC Status
Wino can already be described as:

- `Technical POC: achieved`
- `Product POC: advanced / partially achieved`
- `Business POC: not yet validated`
- `Pilot readiness after hardening: realistic`
- `Full production readiness: not yet`

Why:
- the architecture and feature set are already broad enough to prove feasibility,
- user and merchant workflows exist in real code,
- but release hardening and controlled field validation are still needed before stronger business claims.

## 8) Main Gaps Before A Stronger POC
The current POC is limited by a few known issues already documented in the repo:
- app `baseUrl` is still hardcoded locally,
- some server defaults are still development-friendly,
- OTP and production security need hardening,
- localization is improved but still incomplete,
- monitoring, alerting, and runbooks are not complete,
- Flutter end-to-end validation is still limited.

These do not invalidate the technical POC, but they do limit launch confidence.

## 9) Recommended Next POC Step
The best next step is not a large rebuild. It is a field-shaped pilot.

Recommended next move:
1. harden release-critical settings,
2. switch app/server configuration to environment-driven values,
3. recruit a limited merchant pilot group,
4. run a 4-8 week pilot in one geographic cluster,
5. measure discovery, trust, merchant activity, and operational friction.

## 10) Web-Backed Context
Recent external signals support the relevance of this POC direction:
- DataReportal reports 55.6 million mobile connections, 37.8 million internet users, and 79.5% internet penetration in Algeria based on late-2025 data.
- World Bank country data shows Algeria at 46.8 million population in 2024 and confirms the broader digital and macro context.
- SATIM states that more than 51,000 electronic payment terminals and 500+ web merchants are active on its platform.
- APS reported on 2025-12-14 that Algerian authorities called for more facilitation to develop e-commerce while ensuring digital security.

## 11) Sources
- DataReportal, Digital 2026: Algeria: https://datareportal.com/reports/digital-2026-algeria
- World Bank, Algeria data: https://data.worldbank.org/country/algeria
- SATIM, Qui sommes nous: https://www.satim.dz/index.php/fr/satim/qui-sommes-nous
- APS, e-commerce facilitation and digital security, 2025-12-14: https://www.aps.dz/fr/presidence-news/mj65b5vk-le-president-de-la-republique-affirme-la-necessite-d-accorder-davantage-de-facilitations
