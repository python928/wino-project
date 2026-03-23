# Memoire Research Dossier and Source Bank (Wino)

Last updated: 2026-03-23

This file is the strongest university-facing documentation pack in the repo. It combines:
- the current code reality,
- a thesis structure inspired by the reviewed PDF (`/home/anti-problems/Desktop/editing/MasterThesis.pdf`),
- official and academic sources on Algeria's digital, payment, and regulatory context,
- and a concrete writing plan for the memoire.

The goal is not only to help write faster. The goal is to make the memoire more defensible, better sourced, and better aligned with what the code actually does.

## 1) What the reviewed PDF suggests structurally
The reviewed thesis PDF follows a classical academic rhythm:
- General Introduction
- chaptered body
- Conclusion
- References

That structure is still good for Wino, but the chapter sequence should be more explicitly adapted to an applied software artifact.

The strongest chapter progression for Wino is:
- market and research problem,
- local constraints and stakeholder needs,
- architecture and design logic,
- implementation and current system reality,
- evaluation, limitations, and future work.

This gives the memoire a clearer research story than a generic "analysis then development" structure.

## 2) Stronger thesis title options
### English options
1. Design and Evaluation of a Trust-Aware Local Commerce Platform for the Algerian Market
2. Wino: An Explainable O2O Local Commerce Platform for Nearby Discovery, Trust, and Merchant Growth in Algeria
3. Building a Local Marketplace Artifact for Algeria: Recommendation, Trust, and Monetization in One Mobile Platform
4. Engineering a Proximity-Driven and Trust-Aware Local Commerce System for Algeria
5. Designing a Mobile Local Commerce Artifact for Algeria: Discovery, Trust, and Merchant Growth

### English title + subtitle options
1. Wino: A Trust-Aware Local Commerce Platform for Algeria
   Subtitle: Design, Implementation, and Evaluation of a Mobile O2O Artifact
2. Engineering Local Digital Commerce for Algeria
   Subtitle: A Design Science Study of Nearby Discovery, Trust, and Merchant Monetization
3. Wino: Designing Explainable Local Commerce Under Algerian Market Constraints
   Subtitle: A Socio-Technical Artifact for Discovery, Credibility, and Merchant Growth

### French options
1. Conception et evaluation d'une plateforme de commerce local orientee confiance pour le marche algerien
2. Wino : une plateforme O2O de commerce local integrant proximite, confiance et croissance marchande en Algerie
3. Conception et evaluation d'un systeme mobile de commerce local explicable pour l'Algerie
4. Ingenierie d'une plateforme de commerce local mobile adaptee au contexte algerien

### Arabic options
1. تصميم وتقييم منصة تجارة محلية رقمية موجهة للسوق الجزائري تجمع بين القرب والثقة ونمو التاجر
2. وينو: منصة تجارة محلية O2O قابلة للتفسير للسوق الجزائري
3. هندسة منصة تجارة محلية رقمية تراعي القرب والثقة وواقع السوق الجزائري

### Best practical recommendation
If you want the safest academic title, use:

Design and Evaluation of a Trust-Aware Local Commerce Platform for the Algerian Market

If you want the most distinctive title, use:

Wino: An Explainable O2O Local Commerce Platform for Nearby Discovery, Trust, and Merchant Growth in Algeria

## 3) Strong academic positioning
The most defensible academic positioning is:
- Design Science Research,
- socio-technical systems thinking,
- applied local-commerce / O2O platform design,
- and selective use of explainability and trust literature.

### 3.1 Why Design Science Research fits
Wino is not only a software implementation. It is an artifact intentionally designed to solve a concrete market problem. That aligns strongly with Design Science Research because:
- there is a real problem environment,
- an artifact is built to address it,
- the artifact can be evaluated,
- and the knowledge contribution comes from both the design logic and the implemented result.

### 3.2 Why a socio-technical lens fits
Wino's success cannot be explained by code quality alone. The system interacts with:
- end users,
- merchants,
- moderation processes,
- trust expectations,
- payment infrastructure,
- local operating constraints.

This makes a purely technical framing too narrow. A socio-technical framing is stronger because it explains why geography, trust, and operational realism matter.

### 3.3 Why O2O local commerce fits better than pure e-commerce
Wino is better framed as an O2O local-commerce system than a classic online checkout marketplace because its value is concentrated in:
- finding nearby offers,
- clarifying merchant credibility,
- helping users compare local options,
- enabling direct contact and local completion paths,
- supporting merchants with local visibility and growth tools.

### 3.4 Why explainability belongs in the memoire
Explainability matters in Wino for two reasons:
- for the user, trust and relevance need to feel understandable,
- for the merchant, metrics must help action, not only display counters.

This is a strong bridge between recommender-system literature and real product design.

## 4) Problem statement draft
A suitable problem statement is:

Users in Algerian local commerce contexts need nearby, trustworthy, and interpretable product discovery, while small merchants need simple digital publishing, promotion, and monetization tools. However, many marketplace experiences either assume mature digital payment and logistics infrastructure or fail to integrate trust, local relevance, and merchant usability in one coherent system. This creates a gap between conventional marketplace models and the operational realities of Algerian local commerce.

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
6. How should a local-commerce artifact be evaluated when not all transactions are fully digitized end-to-end?

## 6) Research hypotheses
1. Proximity-aware discovery improves perceived relevance compared with generic listing order.
2. Weighted trust and moderation signals reduce the visible impact of low-credibility content.
3. Simple explanatory merchant UI increases usability compared with raw counters only.
4. A hybrid localization strategy is more practical in a living codebase than a full one-shot migration.
5. Gradual monetization is more adoptable than early hard paywalls for small merchants.
6. A unified `Store == User` model reduces implementation and operational complexity without preventing core marketplace functionality.

## 7) Why Algeria is a meaningful research context
### 7.1 Digital reach is now strong enough to justify the artifact
DataReportal's Digital 2026: Algeria report, published in late 2025 using late-2025 data, reports:
- 55.6 million mobile connections,
- 37.8 million internet users,
- 79.5% internet penetration,
- 27.5 million social media identities.

This is enough to support a serious mobile-first local-commerce thesis.

### 7.2 Payment infrastructure is improving, but not uniformly mature
SATIM reports:
- more than 51,000 TPE terminals,
- more than 1,350 banking automates,
- more than 500 operational web merchants on its platform.

APS reported on 2025-10-15 that DZ Mob Pay had already exceeded 70,000 users and 10,000 merchants since its launch in early 2025.

This suggests progress, but not total maturity. That makes Wino's gradual monetization and proof-based workflows easier to justify academically.

### 7.3 Regulation and formal digitalization are moving forward
The Algerian legal and institutional environment also matters:
- Law No. 18-05 of 2018 sets the general rules relating to electronic commerce.
- APS reported on 2025-12-14 that authorities called for more facilitation for e-commerce development while maintaining digital security.
- the Algerian tax authority launched more digital payment services in 2025, such as `Qassimatouka` and online payment for commerce-registry stamp duties.

Inference from these sources:
- the environment is increasingly supportive of digital transactions,
- but trust, usability, and operational adaptation still remain major design problems.

### 7.4 Local trust and merchant simplicity remain unresolved problems
Academic and practical sources both suggest that in emerging or partially digitized markets:
- trust remains decisive,
- SME adoption remains uneven,
- and local usability constraints matter.

That is exactly where Wino tries to contribute.

## 8) Suggested chapter plan with stronger titles
### General Introduction
Suggested title:
- General Introduction: Local Commerce Digitization, Trust, and the Algerian Opportunity

Cover:
- context and motivation,
- Algerian market reality,
- research problem,
- objectives,
- research questions,
- thesis plan.

### Chapter 1: Background and Conceptual Foundations
Suggested title:
- Chapter 1: Local Commerce Platforms, Recommendation, Trust, and Explainability

Cover:
- local commerce platforms,
- recommender systems,
- trust and safety in marketplaces,
- explainability in recommender and analytics systems,
- O2O commerce.

### Chapter 2: Algerian Context, Requirements, and Stakeholders
Suggested title:
- Chapter 2: Algerian Digital Commerce Context and System Requirements

Cover:
- Algerian digital context,
- payment and trust context,
- legal and regulatory context,
- stakeholder analysis,
- functional requirements,
- non-functional requirements.

### Chapter 3: System Design and Architecture
Suggested title:
- Chapter 3: Design of the Wino Artifact

Cover:
- domain model,
- `Store == User`,
- backend architecture,
- Flutter architecture,
- API map,
- localization strategy,
- deep-link strategy,
- trust and monetization architecture.

### Chapter 4: Implementation
Suggested title:
- Chapter 4: Implementation of a Trust-Aware Local Commerce Platform

Cover:
- implemented modules,
- trust workflows,
- wallet, subscriptions, and ads,
- onboarding and location education,
- current branding and UX state,
- explainability and localization progress.

### Chapter 5: Evaluation and Discussion
Suggested title:
- Chapter 5: Evaluation, Limitations, and Discussion

Cover:
- recommendation metrics,
- trust metrics,
- merchant KPIs,
- UX discussion,
- production-readiness limits,
- future work.

### Conclusion
Suggested title:
- General Conclusion and Future Perspectives

Cover:
- summary of contributions,
- what was achieved,
- limitations,
- future direction.

## 9) Methodology and evaluation strategy
### 9.1 Research strategy
The strongest methodology is:
- Design Science Research as the main research methodology,
- supported by system analysis, implementation evidence, and measured evaluation.

### 9.2 Evaluation strategy
The evaluation should be mixed, not purely algorithmic.

Recommended evaluation layers:
- artifact evaluation:
  does the system implement the intended architecture and workflows?
- technical evaluation:
  latency, endpoint reliability, recommendation metrics, system correctness.
- trust and moderation evaluation:
  report quality, low-credibility ratio, moderation outcomes.
- UX evaluation:
  onboarding completion, merchant understanding, nearby-flow usefulness.
- business and product evaluation:
  merchant activation, repeat publishing, conversion to contact/share.

### 9.3 If you cannot run a full field experiment
If a full field pilot is not feasible before submission, the memoire can still be strong by combining:
- code evidence,
- architectural analysis,
- local-market justification,
- scenario-based evaluation,
- partial metrics from implemented subsystems,
- and transparent limitations.

That is much stronger than pretending full production validation already exists.

## 10) Ready-to-use chapter material
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
- active routing is `RouteGenerator` with named routes,
- state management is `Provider` + `ChangeNotifier`,
- API communication goes through `ApiService`,
- localization is hybrid:
  - generated ARB/localization files for typed strings,
  - `runtime_translations.dart` as migration fallback for legacy strings,
- deep links are supported through short links and custom schemes,
- the current visible brand is `Wino`.

Recent architectural refinements worth citing:
- the app now uses `WinoApp` as the root widget,
- Android local notifications use `wino_channel`,
- device registration is aligned around `/api/notifications/devices/`,
- location permission education was centralized in shared Flutter helper code,
- some placeholder or legacy feature folders were removed.

### Market and business chapter
You can write this chapter directly from the following synthesis:

Wino targets a specific market gap in Algeria: users need nearby and trustworthy discovery, while small merchants need simple publishing and promotion tools that do not assume a perfectly mature digital commerce infrastructure.

The Algerian digital context is now strong enough to support this direction. DataReportal's late-2025 data for Algeria indicates high internet and mobile reach. World Bank country data confirms the broader demographic and digital context. SATIM and APS sources show that electronic payment infrastructure and mobile payment usage are improving. However, academic and practical sources still show that trust, merchant adoption, local coordination, and payment maturity remain uneven.

Because of that, Wino is best positioned not as a generic marketplace, but as:
- a local discovery platform,
- a trust-aware marketplace,
- a lightweight merchant growth system.

Its strongest local differentiation comes from combining:
- nearby/local filtering,
- review/report/trust mechanisms,
- promotion, wallet, and subscriptions,
- share flows, deep links, and QR,
- multilingual support,
- gradual explainability for merchants.

### Current-state and limitations chapter
You can write this chapter directly from the following synthesis:

The project has moved beyond a basic CRUD marketplace and already implements:
- catalog management for products, packs, and promotions,
- reviews, favorites, and reports,
- trust scoring and abuse handling,
- analytics events and recommendations,
- ads campaigns with click tracking,
- wallet purchase requests with proof images,
- subscription plans and payment requests,
- notifications and device registration,
- feedback flow with admin review,
- deep links, sharing, and QR flows.

Recent implementation progress that should be highlighted:
- first-run onboarding includes a visible language picker,
- location and GPS education is shared across important screens,
- nearby behavior is more consistent in home, search, and merchant profile flows,
- some empty/error/loading states were improved in subscription and dashboard screens,
- the merchant ads dashboard includes clearer explanation of metrics,
- localization is more structured, with common strings resolving through generated localizations first where possible,
- visible branding is more aligned around `Wino`.

At the same time, remaining limitations should be presented honestly:
- some backend settings are still development-friendly and need production hardening,
- the app base URL is still hardcoded locally,
- OTP flow is not yet fully production-grade,
- observability is still incomplete,
- localization has improved but is not yet complete across all screens,
- automated testing is still smaller than the size of the system, especially in Flutter and end-to-end coverage,
- some legacy naming remains in internal identifiers such as `dzlocal_shop`,
- explainability is improving for merchants, but is still weaker for end users in trust and recommendation flows.

This balance is academically useful because it allows the thesis to describe Wino as:
- implemented and functional,
- architecturally meaningful,
- locally adapted,
- but still realistic about what remains before full production readiness.

### Technical contribution chapter
Technically, Wino is an applied software artifact that combines:
- a modular Django backend,
- a Flutter Android client,
- trust and moderation mechanisms,
- recommendation and analytics pipelines,
- and merchant monetization features.

Its strongest technical contributions are:
- unifying the merchant/store concept through `Store == User`,
- integrating trust scoring into reports and reviews,
- combining recommendation logic with practical marketplace flows,
- supporting gradual monetization through wallet, ads, and subscriptions,
- evolving the UX toward better onboarding, localization, and explainability.

## 11) What the code already gives you as evidence
The codebase already supports a serious memoire narrative because it includes:
- recommendations endpoint and analytics logging,
- trust scoring and abuse flags,
- product and store reporting,
- review credibility handling,
- wallet and subscription monetization flows,
- feedback capture and admin review,
- deep links and QR/share flows,
- onboarding and location education,
- multilingual UX foundations.

This is enough to describe the project as an applied artifact, not just a classroom prototype.

## 12) Recent implementation changes worth mentioning in the memoire
1. first-run launch screen now exposes language selection clearly
2. nearby and GPS permission education is centralized
3. merchant ads dashboard includes clearer metric explanation
4. localization flow is better organized between ARB and runtime fallback
5. device registration docs and app config now align on one active path
6. visible branding moved further toward `Wino`

These changes help the memoire because they show iterative refinement and product maturation.

## 13) Suggested metrics section
### Recommendation
- Precision@K
- Recall@K
- NDCG@K
- recommendation CTR

### Trust and moderation
- low-credibility review ratio
- effective report ratio
- number of moderated items
- verified-store interaction lift

### Merchant growth
- first publish rate
- ad activation rate
- subscription request completion rate
- retention after first monetization action

### UX and interaction
- conversion from search/nearby to detail/contact/share
- completion of onboarding and language selection
- GPS setup completion rate for merchants
- merchant understanding score

## 14) Suggested figures and tables
### Figures
1. Global system architecture
2. Backend module interaction diagram
3. Flutter application layer diagram
4. Nearby/location decision flow
5. Subscription + wallet + ads relationship diagram
6. Trust signal and moderation flow
7. Search/recommendation event pipeline
8. Merchant lifecycle from onboarding to monetization

### Tables
1. Backend modules and responsibilities
2. Flutter modules and responsibilities
3. Main API families and endpoints
4. Evaluation metrics by subsystem
5. Current limitations and future work
6. Competitor comparison for Algerian market fit
7. Official and academic source classification

## 15) Suggested writing style
From the reviewed PDF, the strongest reusable structural lesson is not its topic, but its rhythm:
- clear introduction,
- chapter-by-chapter progression,
- explicit conclusion,
- references at the end.

For Wino, improve on that model by:
- keeping tighter problem framing,
- using more explicit evaluation criteria,
- separating code reality from future roadmap,
- distinguishing official sources from academic sources,
- and citing concrete dates when using current market evidence.

## 16) Expanded external sources and links
### A. Official Algerian and market context
1. DataReportal - Digital 2026: Algeria
https://datareportal.com/reports/digital-2026-algeria

2. World Bank - Algeria country data
https://data.worldbank.org/country/algeria

3. World Bank - Individuals using the Internet (% of population), Algeria
https://data.worldbank.org/indicator/IT.NET.USER.ZS?locations=DZ

4. SATIM - Company and network context
https://www.satim.dz/index.php/fr/satim/qui-sommes-nous

5. SATIM - TPE payment operations
https://www.satim.dz/index.php/fr/services-cib/operations-de-paiement

6. SATIM - Certified web merchants
https://www.satim.dz/index.php/fr/e-paiement/webmarchands-certifies

7. APS - DZ Mob Pay exceeded 70,000 users and 10,000 merchants on 2025-10-15
https://www.aps.dz/economie/banque-et-finances/mgsey939-%D8%A7%D9%84%D8%AF%D9%81%D8%B9-%D8%B9%D8%A8%D8%B1-%D8%A7%D9%84%D9%87%D8%A7%D8%AA%D9%81-%D8%A7%D9%84%D9%86%D9%82%D8%A7%D9%84-%D8%A7%D9%94%D9%83%D8%AB%D8%B1-%D9%85%D9%86-70-%D8%A7%D9%94%D9%84%D9%81-%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85-%D9%84%D9%86%D8%B8%D8%A7%D9%85-%D8%A7%D9%84%D8%AF%D9%81%D8%B9-%D8%AF%D9%8A-%D8%B2%D8%A7%D8%AF-%D9%85%D9%88%D8%A8-%D8%A8%D8%A7%D9%8A

8. APS - e-commerce facilitation and digital security, 2025-12-14
https://www.aps.dz/fr/presidence-news/mj65b5vk-le-president-de-la-republique-affirme-la-necessite-d-accorder-davantage-de-facilitations

9. Journal Officiel - Law No. 18-05 of 2018 relating to electronic commerce
https://www.joradp.dz/FTP/JO-FRANCAIS/2018/F2018028.pdf

10. Algerian tax authority - launch of `Qassimatouka`, 2025-03-05
https://www.mfdgi.gov.dz/fr/a-propos/actu-fr/lancement-qassimatouka

11. Algerian tax authority - online payment service for commerce-registry stamp duties, 2025-12-24
https://www.mfdgi.gov.dz/fr/a-propos/actu-fr/paiement-des-droits-de-timbre-du-registre-de-commerce-en-ligne

12. Algerian tax authority - launch of `Tabioucom`, 2024-08-08
https://www.mfdgi.gov.dz/fr/a-propos/actu-fr/lancemant-plateforme-tabioukom-fr

13. APS - coordination meeting on e-commerce, 2025-09-27
https://www.aps.dz/fr/economie/commerce-et-service/mg2paoyf-mme-abdellatif-preside-une-reunion-de-coordination-sur-le-e-commerce

### B. Design science and systems framing
14. Hevner et al. (2004), Design Science in Information Systems Research
https://aisel.aisnet.org/misq/vol28/iss1/6/

15. Peffers et al. (2007), A Design Science Research Methodology for Information Systems Research
https://doi.org/10.2753/MIS0742-1222240302

16. March and Storey (2008), Design Science in the Information Systems Discipline
https://aisel.aisnet.org/misq/vol32/iss4/6/

17. Baxter and Sommerville (2011), Socio-technical systems: From design methods to systems engineering
https://doi.org/10.1016/j.intcom.2010.07.003

### C. Recommendation, explainability, and trust
18. Zhang and Chen (2020), Explainable Recommendation: A Survey and New Perspectives
https://doi.org/10.1561/1500000066

19. Josang, Ismail, and Boyd (2007), A survey of trust and reputation systems for online service provision
https://doi.org/10.1016/j.dss.2005.05.019

20. Hendrikx, Bubendorfer, and Chard (2015), Reputation systems: A survey and taxonomy
https://doi.org/10.1016/j.jpdc.2014.08.004

21. Dellarocas (2003), The Digitization of Word-of-Mouth: Promise and Challenges of Online Feedback Mechanisms
https://econpapers.repec.org/article/inmormnsc/v_3a49_3ay_3a2003_3ai_3a10_3ap_3a1407-1424.htm

### D. O2O, adoption, and emerging-market context
22. Gupta and Jeyaraj (2021), Online-to-Offline (O2O) Commerce in Emerging Markets: Analysis of the Retail Sector
https://doi.org/10.1080/10599231.2021.1983501

23. Butta et al. (2022), Effect of Trust on e-Shopping Adoption - An Emerging Market Context
https://doi.org/10.1080/15332861.2021.1927436

24. Hassen et al. (2020), Factors Influencing the adoption of e-commerce by SMEs in Algeria: a qualitative study
https://doi.org/10.31436/ijpcc.v6i2.147

25. Drivers of E-Commerce Adoption in Algeria (2025), TAM and TPB field study
https://asjp.cerist.dz/en/article/273952

26. Kreifeur and Hacene (2025), An Analytical Study of E-Commerce in Algeria: Between Reality and Aspirations
https://doi.org/10.31435/ijitss.3(47).2025.3559

27. E-Banking Adoption by Algerian Bank Customers (2023)
https://doi.org/10.4018/IJESMA.317943

28. Benseddik (2025), Electronic Payment Systems in Algeria
https://asjp.cerist.dz/en/article/265435

29. Chabani and Chabani (2025), Adoption and Analysis of Electronic Payment Methods in Algeria: A Case Study of Algérie Télécom (2022-2024)
https://asjp.cerist.dz/en/article/282109

## 17) How to use these sources in the memoire
Use them in layers:
- official sources:
  for market, regulation, infrastructure, and institutional context.
- academic theory sources:
  for Design Science Research, socio-technical framing, explainability, trust, and O2O theory.
- Algeria-specific academic sources:
  for local adoption barriers, SME readiness, and digital payment interpretation.

Recommended writing rule:
- do not cite only DataReportal for everything,
- do not cite only code files for market claims,
- do not cite only academic theory for Algeria-specific realities.

The memoire becomes stronger when each kind of claim is backed by the right kind of source.

## 18) A good abstract starter
### Short version
This thesis presents Wino, an Android-first local digital commerce platform designed for the Algerian market. The platform integrates proximity-aware discovery, trust and moderation mechanisms, merchant growth tools, and progressive monetization workflows within a single practical architecture. The work is framed as a design science artifact evaluated against local market constraints, including geography, trust, partial payment digitization, and the need for interpretable merchant-facing analytics.

### Longer version
This thesis investigates the design and evaluation of Wino, a mobile local-commerce platform built for the Algerian market. The proposed artifact combines nearby discovery, trust-aware interaction, merchant content publishing, and gradual monetization in one Android-first O2O system. The work is positioned within Design Science Research and socio-technical systems thinking, because the target problem is not only computational but also operational and market-specific. The thesis argues that local relevance, trust calibration, merchant usability, and explainability are central requirements for digital commerce systems operating under partial payment maturity and strong proximity constraints. The implementation is analyzed through the current codebase and evaluated using technical, behavioral, trust, and merchant-oriented measures.

## 19) Practical advice for the memoire defense
During defense, emphasize:
- the problem is real and local,
- the artifact is implemented, not imaginary,
- the architecture is coherent,
- the market context is now better documented with official and academic sources,
- the project is honest about its remaining limitations,
- and the contribution is both technical and practical.

That combination is stronger than claiming a perfect finished product.
