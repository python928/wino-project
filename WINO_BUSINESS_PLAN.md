# Wino Business Plan (BP)

Last updated: 2026-03-23

## 1) Executive Summary
Wino is an Algeria-focused, Android-first local commerce platform built around four linked ideas:
- nearby discovery,
- trust-aware interaction,
- lightweight merchant publishing,
- gradual merchant monetization.

The business opportunity is not to imitate a generic marketplace. It is to serve local commerce conditions where users care about proximity and trust, merchants need lighter digital tools, and payments are improving but not uniformly mature.

## 2) Problem
Local commerce in Algeria is often fragmented across:
- social media pages,
- direct messaging,
- classified-style listings,
- informal recommendation and word-of-mouth.

That creates several gaps:
- discovery is noisy,
- trust is weak or inconsistent,
- merchant performance tools are limited,
- customer journeys are hard to measure,
- monetization tools are usually detached from the core merchant workflow.

## 3) Solution
Wino combines in one product:
- store and merchant profile presence,
- product, pack, and promotion publishing,
- nearby and search-driven discovery,
- trust signals through reviews, reports, and moderation,
- share, QR, and deep-link distribution,
- merchant monetization building blocks through ads, subscriptions, and wallet flows.

This makes Wino best positioned as a trust-aware local commerce platform rather than a checkout-first marketplace.

## 4) Market Logic
Recent web-backed signals suggest that the timing is reasonable:
- DataReportal reports 37.8 million internet users and 79.5% internet penetration in Algeria based on late-2025 data.
- The same report shows 55.6 million mobile connections and 27.5 million social media identities, which supports mobile-first and sharing-heavy product behavior.
- SATIM reports more than 51,000 electronic payment terminals and 500+ active web merchants on its platform, indicating growing payment infrastructure.
- APS reported on 2025-12-14 that Algerian authorities called for more facilitation to develop e-commerce while preserving digital security.

Interpretation:
- digital reach is already strong enough for user acquisition,
- payment digitization is improving,
- but there is still room for a product that reduces trust and merchant-operations friction.

## 5) Target Customers
### Primary users
- consumers in urban and semi-urban Algeria looking for nearby offers and clearer merchant credibility.

### Primary merchants
- small and medium merchants who are active or semi-active online, but still rely heavily on phone calls, chat apps, or social channels to close sales.

### Early adopter profile
- merchants with frequent inventory updates,
- visually marketable products,
- strong need for local reach,
- willingness to experiment with digital visibility tools.

## 6) Go-To-Market Plan
### Stage 1: Controlled pilot
- launch in one city or one wilaya cluster,
- recruit a limited merchant cohort directly,
- onboard merchants manually,
- drive user traffic through merchant sharing, QR, and deep links.

### Stage 2: Local density strategy
- increase merchant density in selected zones,
- improve repeat usage through favorites, promotions, and notifications,
- strengthen trust signals and user education.

### Stage 3: Monetization expansion
- introduce paid visibility selectively,
- expand subscriptions for merchants who already publish consistently,
- use analytics to identify merchants ready for promotion tools.

## 7) Revenue Model
### Core revenue lines
- subscription plans for merchant access or enhanced visibility,
- sponsored listings or ad campaigns,
- wallet or coin-based spend for merchant actions.

### Revenue principle
Monetization should follow demonstrated value:
- first activation,
- then retention,
- then paid growth tools.

That sequence is especially important in this market context.

## 8) Operating Model
The near-term operating model should remain lean:
- product and engineering maintain the core app and backend,
- admin/operators handle moderation and payment-review workflows,
- merchant success focuses on onboarding and campaign understanding,
- support and feedback loops feed product iteration.

In the current codebase, some monetization flows already rely on manual review. That is acceptable for an early-stage launch if expectations and SLAs are communicated clearly.

## 9) 12-Month Execution Plan
### Months 1-3
- complete production hardening,
- move app/server config to environment-based values,
- finalize core localization coverage,
- validate notifications and release operations,
- prepare merchant pilot materials.

### Months 4-6
- run the first controlled merchant pilot,
- measure search, nearby, trust, and merchant publishing funnels,
- improve onboarding and merchant explainability based on pilot feedback.

### Months 7-9
- expand into additional local clusters,
- refine ranking, recommendation, and trust presentation,
- introduce more structured merchant lifecycle communication.

### Months 10-12
- scale paid visibility carefully,
- improve ROI storytelling in merchant dashboards,
- prepare a stronger case for broader rollout or partnership expansion.

## 10) Financial Planning Logic
This repo does not yet justify a precise top-down revenue forecast, so the safest business-plan format is scenario-based.

### Conservative planning model
Revenue drivers:
- active merchants,
- paying merchant share,
- average subscription fee,
- average campaign spend,
- repeat usage of paid tools.

Cost drivers:
- engineering and maintenance,
- infrastructure,
- moderation/support,
- merchant acquisition and onboarding.

### Planning rule
Do not treat national-scale forecasts as credible until pilot retention, merchant repeat publishing, and paid conversion are measured.

## 11) Main Risks
### Product risks
- nearby relevance may be weaker than expected in low-density merchant zones,
- trust features may exist technically but remain under-explained to users,
- merchant dashboards may still feel too technical.

### Operational risks
- hardcoded local config and development-friendly settings reduce release readiness,
- OTP and notification validation still need stronger production confidence,
- manual payment-review workflows can create friction if not communicated well.

### Business risks
- merchants may compare Wino to free social posting habits,
- adoption may depend on local density more than national reach,
- monetization introduced too early could reduce merchant activation.

## 12) Mitigation Strategy
- start geographically narrow,
- focus on merchant density before geographic breadth,
- make trust and contact flows extremely clear,
- keep early monetization selective,
- use the current feedback and analytics layers to guide iteration,
- improve explainability for both merchants and end users.

## 13) Why Wino Is Defensible
Wino is defensible if it keeps building where generic listing platforms are weaker:
- local relevance,
- structured trust,
- merchant growth inside the same system,
- multilingual and market-specific UX,
- a practical O2O model rather than an imported pure-checkout assumption.

## 14) Immediate Business Priority
The immediate priority is not writing a larger strategy deck. It is converting the existing codebase into a measured local pilot with strong learning loops.

If that succeeds, the business case becomes much stronger than a purely theoretical plan.

## 15) Sources
- DataReportal, Digital 2026: Algeria: https://datareportal.com/reports/digital-2026-algeria
- World Bank, Algeria data: https://data.worldbank.org/country/algeria
- SATIM, Qui sommes nous: https://www.satim.dz/index.php/fr/satim/qui-sommes-nous
- APS, e-commerce facilitation and digital security, 2025-12-14: https://www.aps.dz/fr/presidence-news/mj65b5vk-le-president-de-la-republique-affirme-la-necessite-d-accorder-davantage-de-facilitations
