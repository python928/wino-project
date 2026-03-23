# Memoire Research Dossier (Wino)

Last updated: 2026-03-23

This file is the strongest university-facing documentation pack in the repo. It combines:
- the current code reality,
- a thesis structure inspired by the reviewed PDF (`/home/anti-problems/Desktop/editing/MasterThesis.pdf`),
- external sources on Algeria’s digital and payment context,
- and a concrete writing plan for the memoire.

## 1) What the reviewed PDF suggests structurally
The reviewed thesis PDF follows a classical structure:
- General Introduction
- chaptered body
- Conclusion
- References

The body is organized as a progressive literature and analysis sequence. For Wino, the same structure should be kept, but the chapters should move from:
- market / research problem,
- to system design,
- to implementation,
- to evaluation.

That gives a more appropriate structure for an applied software-engineering / information-systems memoire.

## 2) Strong proposed thesis titles
### English options
1. Design and Evaluation of a Trust-Aware Local Commerce Platform for the Algerian Market
2. Wino: An Explainable O2O Local Commerce Platform for Nearby Discovery, Trust, and Merchant Growth in Algeria
3. Building a Local Marketplace Artifact for Algeria: Recommendation, Trust, and Monetization in One Mobile Platform

### French options
1. Conception et evaluation d'une plateforme de commerce local orientee confiance pour le marche algerien
2. Wino : une plateforme O2O de commerce local integrant proximite, confiance et croissance marchande en Algerie

### Arabic option
- تصميم وتقييم منصة تجارة محلية رقمية موجهة للسوق الجزائري تجمع بين القرب والثقة ونمو التاجر

## 3) Strong academic positioning
The most defensible academic positioning is:
- Design Science Research
- socio-technical systems view
- applied local-commerce / O2O platform design

Why this is strong:
- the project is not only code; it is an artifact built for a concrete market problem,
- the problem is not purely algorithmic; it involves merchants, users, trust, geography, payments, and UX,
- the evaluation can combine technical, behavioral, and business-oriented metrics.

## 4) Problem statement draft
A suitable problem statement is:

Users in Algerian local commerce contexts need nearby, trustworthy, and interpretable product discovery, while small merchants need simple digital publishing, promotion, and monetization tools. However, existing marketplace experiences often separate discovery from trust, and often assume fully mature digital payment and logistics infrastructures. This creates a gap between technical marketplace models and the operational realities of the Algerian market.

Wino addresses this gap by proposing an Android-first O2O local commerce platform that integrates proximity-aware discovery, trust and moderation signals, merchant growth tools, and progressive monetization workflows within one practical architecture.

## 5) Research questions
### Main question
How can a local digital commerce platform be designed to balance nearby discovery, trust, explainability, and merchant growth under realistic Algerian market constraints?

### Sub-questions
1. What is the effect of combining nearby and area-based filtering with behavioral recommendation?
2. How do trust signals such as reports, reviews, and verification affect platform credibility?
3. How useful is the `Store == User` model as a simplification strategy for an applied marketplace architecture?
4. How does explainability in merchant dashboards influence usability and decision confidence?
5. How can monetization be introduced gradually without blocking merchant adoption?

## 6) Research hypotheses
1. Proximity-aware discovery improves perceived relevance compared with generic listing order.
2. Weighted trust and moderation signals reduce the visible impact of low-credibility content.
3. Simple explanatory merchant UI increases usability compared with raw counters only.
4. A hybrid localization strategy is more practical in a living codebase than a full one-shot migration.
5. Gradual monetization is more adoptable than early hard paywalls for small merchants.

## 7) Suggested chapter plan
### General Introduction
- context and motivation
- Algerian market reality
- research problem
- objectives
- thesis plan

### Chapter 1: Background and Related Concepts
- local commerce platforms
- recommender systems
- trust and safety in marketplaces
- explainability in recommender and analytics systems
- O2O commerce

### Chapter 2: Context, Requirements, and Market Fit
- Algerian digital context
- Algerian payment and trust context
- stakeholder analysis
- functional requirements
- non-functional requirements

### Chapter 3: System Design and Architecture
- domain model
- `Store == User`
- backend architecture
- Flutter architecture
- API map
- localization strategy
- deep-link strategy

### Chapter 4: Implementation
- implemented modules
- trust workflows
- wallet/subscriptions/ads
- onboarding and location education
- current branding and UX state

### Chapter 5: Evaluation and Discussion
- recommendation metrics
- trust metrics
- merchant KPIs
- UX discussion
- limitations
- future work

### Conclusion
- summary of contributions
- what was achieved
- what remains open

### References
- academic references
- official / market references

## 8) Ready-to-use chapter material
### Architecture chapter
You can write this chapter directly from the following synthesis:

Wino is built as a two-part artifact:
- a Django + Django REST Framework backend,
- and a Flutter Android-first mobile client.

The backend is organized into clearly separated apps:
- `users`: authentication, OTP, profile, followers, store reports, system settings, trust settings
- `catalog`: products, packs, promotions, reviews, favorites, product reports
- `ads`: ad campaigns and click tracking
- `notifications`: in-app notifications and FCM device registration
- `subscriptions`: plans, payment requests, merchant access status, dashboard
- `wallet`: coin balances, purchases, and approvals
- `analytics`: interaction logs, trust signals, recommendations
- `feedback`: user feedback and admin review flow

The most important domain decision is:
- `Store == User`

This means the system does not model the store as a separate business entity. Instead, the merchant/store is represented by the same `users.User` model enriched with store-facing fields such as profile, location, verification, and communication data. This reduces domain duplication and keeps account, trust, and monetization flows tightly integrated.

On the mobile side, the architecture follows these rules:
- active routing is `RouteGenerator` with named routes
- state management is `Provider` + `ChangeNotifier`
- API communication goes through `ApiService`
- localization is hybrid:
  - generated ARB/localization files for typed strings
  - `runtime_translations.dart` as migration fallback for legacy strings
- deep links are supported through short links and custom schemes
- the current visible brand is `Wino`

Recent architectural refinements that are worth citing:
- the app now uses `WinoApp` as the root widget
- Android local notifications use `wino_channel`
- device registration is aligned around `/api/notifications/devices/`
- location permission education was centralized in shared Flutter helper code
- some empty placeholder feature folders were removed to keep the structure cleaner

### Market / business chapter
You can write this chapter directly from the following synthesis:

Wino targets a specific market gap in Algeria: users need nearby and trustworthy discovery, while small merchants need simple publishing and promotion tools that do not assume a perfectly mature digital commerce infrastructure.

The Algerian digital context is strong enough to support this product direction:
- DataReportal reports about 55.6 million mobile connections in late 2025
- about 37.8 million internet users
- about 79.5% internet penetration
- about 27.5 million social media identities

This means discovery, sharing, and digital reach are already meaningful at national scale.

The payment and digitization context is improving as well:
- World Bank data confirms a strong rise in internet use over recent years
- SATIM figures show growth in electronic payment infrastructure
- APS reported in October 2025 that DZ Mob Pay exceeded 70,000 users and 10,000 merchants
- APS also reported official support for the development of e-commerce with emphasis on digital security

However, the Algerian market still has characteristics that justify Wino's design:
- geography matters strongly: nearby distance, wilaya, baladiya, and address clarity affect purchase decisions
- trust is not automatic: users need reviews, reports, verification, and moderation signals
- direct contact still matters: many transactions are influenced by phone, messaging, and local communication
- many merchants are not highly technical: they need lighter tools and understandable metrics
- payment digitization is progressing, but fully automated flows cannot always be assumed

Because of that, Wino is best positioned not as a generic marketplace, but as:
- a local discovery platform
- a trust-aware marketplace
- a lightweight merchant growth system

Its competitive advantage in Algeria comes from combining:
- nearby/local filtering
- review/report/trust mechanisms
- promotion, wallet, and subscriptions
- share flows, deep links, and QR
- multilingual support
- gradual explainability for merchants

Compared with common alternatives such as Ouedkniss, Facebook Marketplace, or broader listing platforms, Wino's strongest differentiation is not just inventory display, but the integration of:
- local relevance
- trust signals
- merchant monetization
- interpretability of certain merchant-facing metrics

Recent product improvements strengthen this market fit:
- clearer first-run language selection
- better GPS/location explanation
- stronger ads dashboard explainability
- better localization of merchant-facing flows

### Current-state / limitations chapter
You can write this chapter directly from the following synthesis:

The project has moved beyond a basic CRUD marketplace and already implements several meaningful subsystems:
- catalog management for products, packs, and promotions
- reviews, favorites, and reports
- trust scoring and abuse handling
- analytics events and recommendations
- ads campaigns with click tracking
- wallet purchase requests with proof images
- subscription plans and payment requests
- notifications and device registration
- feedback flow with admin review
- deep links, sharing, and QR flows

Recent implementation progress that should be highlighted:
- first-run onboarding now includes a visible language picker
- location and GPS education is shared across important screens
- nearby behavior is more consistent in home, search, and merchant profile flows
- some empty/error/loading states were improved in subscription and dashboard screens
- the merchant ads dashboard now includes clearer explanation of metrics
- localization is more structured, with common strings resolving through generated localizations first where possible
- visible branding is more aligned around `Wino`

At the same time, the memoire should present remaining limitations honestly:
- some backend settings are still development-friendly and need production hardening
- the app base URL is still hardcoded locally
- OTP flow is not yet fully production-grade
- observability is still incomplete:
  - error tracking
  - tracing
  - alerting
  - runbooks
- localization has improved but is not yet complete across all screens
- automated testing is still smaller than the size of the system, especially in Flutter and end-to-end coverage
- some legacy naming remains in internal identifiers such as `dzlocal_shop` or old config values
- explainability is improving for merchants, but is still weaker for end users in trust/recommendation flows

This balance is academically useful because it allows the thesis to describe Wino as:
- implemented and functional,
- architecturally meaningful,
- locally adapted,
- but still realistic about what remains before full production readiness.

### Technical summary chapter
You can write this chapter directly from the following synthesis:

Technically, Wino is an applied software artifact that combines:
- a modular Django backend,
- a Flutter Android client,
- trust and moderation mechanisms,
- recommendation and analytics pipelines,
- and merchant monetization features.

Its strongest technical contributions are:
- unifying the merchant/store concept through `Store == User`
- integrating trust scoring into reports and reviews
- combining recommendation logic with practical marketplace flows
- supporting gradual monetization through wallet, ads, and subscriptions
- evolving the UX toward better onboarding, localization, and explainability

## 9) What the code already gives you as evidence
The codebase already supports a serious memoire narrative because it includes:
- recommendations endpoint and analytics logging
- trust scoring and abuse flags
- product and store reporting
- review credibility handling
- wallet and subscription monetization flows
- feedback capture and admin review
- deep links and QR/share flows
- onboarding and location education
- multilingual UX foundations

This is enough to describe the project as an applied artifact, not just a classroom prototype.

## 10) Recent implementation changes worth mentioning in the memoire
1. first-run launch screen now exposes language selection clearly
2. nearby and GPS permission education is centralized
3. merchant ads dashboard includes clearer metric explanation
4. localization flow is better organized between ARB and runtime fallback
5. device registration docs and app config now align on one active path
6. visible branding moved further toward `Wino`

These changes help the memoire because they show iterative refinement and product maturation.

## 11) Suggested metrics section
### Recommendation
- Precision@K
- Recall@K
- NDCG@K
- recommendation CTR

### Trust / moderation
- low-credibility review ratio
- effective report ratio
- number of moderated items
- verified-store interaction lift

### Merchant growth
- first publish rate
- ad activation rate
- subscription request completion rate
- retention after first monetization action

### UX / interaction
- conversion from search/nearby to detail/contact/share
- completion of onboarding / language selection
- GPS setup completion rate for merchants
- merchant understanding score (if you do questionnaires)

## 12) Suggested figures and tables
### Figures
1. Global system architecture
2. Backend module interaction diagram
3. Flutter application layer diagram
4. Nearby / location decision flow
5. Subscription + wallet + ads relationship diagram
6. Trust signal and moderation flow

### Tables
1. Backend modules and responsibilities
2. Flutter modules and responsibilities
3. Main API families and endpoints
4. Evaluation metrics by subsystem
5. Current limitations and future work
6. Competitor comparison for Algerian market fit

## 13) Suggested writing style based on the PDF
From the reviewed PDF, the strongest reusable structural lesson is not its topic, but its rhythm:
- clear introduction,
- chapter-by-chapter progression,
- explicit conclusion,
- references at the end.

For Wino, improve on that model by:
- keeping tighter problem framing,
- using more explicit evaluation criteria,
- separating code reality from future roadmap,
- citing stronger official and academic sources.

## 14) External sources and links
### Market / official context
1. DataReportal - Digital 2026: Algeria
https://datareportal.com/reports/digital-2026-algeria

2. World Bank - Individuals using the Internet (% of population), Algeria
https://data.worldbank.org/indicator/IT.NET.USER.ZS?locations=DZ

3. SATIM - Company / network context
https://www.satim.dz/index.php/fr/satim/qui-sommes-nous

4. SATIM - TPE payment operations
https://www.satim.dz/index.php/fr/services-cib/operations-de-paiement

5. APS - Facilitation of e-commerce and digital security (December 15, 2025)
https://www.aps.dz/fr/economie/commerce-et-service/mj7irwdv-des-experts-saluent-les-orientations-du-president-de-la-republique-pour-la-promotion-du-commerce-electronique

6. APS - DZ Mob Pay exceeded 70,000 users and 10,000 merchants (October 15, 2025)
https://www.aps.dz/economie/banque-et-finances/mgsey939-%D8%A7%D9%84%D8%AF%D9%81%D8%B9-%D8%B9%D8%A8%D8%B1-%D8%A7%D9%84%D9%87%D8%A7%D8%AA%D9%81-%D8%A7%D9%84%D9%86%D9%82%D8%A7%D9%84-%D8%A7%D9%94%D9%83%D8%AB%D8%B1-%D9%85%D9%86-70-%D8%A7%D9%94%D9%84%D9%81-%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85-%D9%84%D9%86%D8%B8%D8%A7%D9%85-%D8%A7%D9%84%D8%AF%D9%81%D8%B9-%D8%AF%D9%8A-%D8%B2%D8%A7%D8%AF-%D9%85%D9%88%D8%A8-%D8%A8%D8%A7%D9%8A

### Academic framing
7. Hevner et al. (2004), Design Science in Information Systems Research
https://aisel.aisnet.org/misq/vol28/iss1/10/

8. Peffers et al. (2007), A Design Science Research Methodology for Information Systems Research
https://doi.org/10.2753/MIS0742-1222240302

9. Naiseh et al. (2021), Explainable recommender systems / explanation effects
https://doi.org/10.1007/s11280-021-00916-0

10. Platform ecosystems from a socio-technical perspective
https://doi.org/10.1016/j.jbusres.2021.01.060

## 15) A good abstract starter
This thesis presents Wino, an Android-first local digital commerce platform designed for the Algerian market. The platform integrates proximity-aware discovery, trust and moderation mechanisms, merchant growth tools, and progressive monetization workflows within a single practical architecture. The work is framed as a design science artifact evaluated against local market constraints, including geography, trust, partial payment digitization, and the need for interpretable merchant-facing analytics.

## 16) Practical advice for the memoire defense
During defense, emphasize:
- the problem is real and local,
- the artifact is implemented, not imaginary,
- the architecture is coherent,
- the project is honest about its remaining limitations,
- and the memoire contributes both technically and practically.

That combination is stronger than claiming a perfect finished product.
