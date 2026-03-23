# Memoire Technical and Research Positioning Summary (Wino)

Last updated: 2026-03-23

## 1) Problem framing
Wino addresses a practical Algerian O2O commerce problem:
- users need nearby and trustworthy discovery,
- merchants need simple digital publishing and growth tools,
- and the system must function even when payment and logistics are not fully automated.

This means the project should not be described as only a marketplace UI. It is better described as an applied socio-technical artifact in which:
- geography influences relevance,
- trust influences adoption,
- merchant usability influences activation,
- and monetization must be introduced without breaking local market fit.

## 2) Why the Algerian context matters academically
The Algerian context is not just background. It directly shapes the artifact.

Why it matters:
- proximity is commercially meaningful because wilaya, baladiya, and address clarity affect decision-making,
- trust remains a practical issue in local commerce and informal digital selling,
- direct contact still matters for many transactions,
- digital reach is now strong enough to support mobile-first discovery,
- payment digitization is improving, but fully automated e-commerce assumptions are still too strong for many merchants.

This is what makes Wino academically interesting: it is trying to solve a real mismatch between imported marketplace assumptions and local operational reality.

## 3) Technical stack
- Backend: Django + DRF + JWT + filtering + scoped throttling
- Mobile client: Flutter + Provider/ChangeNotifier
- Notifications: Firebase Messaging + `flutter_local_notifications`
- Deep links: short links + custom schemes
- Optional ops stack: Celery + Redis
- Localization: ARB/generated strings + runtime translation bridge

## 4) Core architectural choice
- `Store == User`

This is one of the strongest technical choices in the project because it:
- reduces domain duplication,
- keeps authentication and merchant identity aligned,
- simplifies trust, moderation, and monetization flows,
- and makes the artifact easier to explain in a memoire.

Instead of modeling a separate heavy store entity, Wino treats the merchant/store as a unified user profile enriched with store-facing fields such as location, communication, and verification-related data.

## 5) Main implemented modules
- Catalog: products, promotions, packs, reviews, favorites
- Trust: product/store reports, review credibility, abuse flags, trust settings
- Analytics: events, trust signals, recommendations, interest profiles
- Monetization: ads, wallet, subscriptions, payment-proof workflows
- Feedback: user feedback with admin review
- Notifications and deep links

These modules matter academically because the system is already richer than a CRUD catalog. It combines discovery, trust, growth, and monetization in one artifact.

## 6) Research-relevant contributions
### 6.1 Hybrid local discovery
Wino does not rely only on generic listing. It combines search, nearby logic, location-aware behavior, and analytics-ready interaction data. That supports a stronger discussion about relevance in local commerce.

### 6.2 Trust and moderation as first-class concerns
The project includes reports, review credibility, abuse handling, and trust settings instead of treating trust as an afterthought. This is important because local marketplace adoption often depends on reducing uncertainty, not just displaying more items.

### 6.3 Architecture adapted to Algerian constraints
The artifact is adapted to:
- proximity-sensitive discovery,
- direct-contact commerce patterns,
- partial/manual payment operations,
- multilingual usage expectations,
- merchant simplicity requirements.

### 6.4 Monetization integrated inside the same artifact
Wallet, subscriptions, and ads are not external business ideas. They are already represented in code. This makes Wino useful for discussing how a local platform can move from usefulness to monetization gradually.

### 6.5 Progressive explainability
The product has started moving toward more explainable merchant UX, especially in dashboard and onboarding areas. That creates a useful bridge between recommendation systems, trust calibration, and human-centered product design.

## 7) Stronger thesis title options
### English
1. Design and Evaluation of a Trust-Aware Local Commerce Platform for the Algerian Market
2. Wino: An Explainable O2O Local Commerce Platform for Nearby Discovery, Trust, and Merchant Growth in Algeria
3. Building a Local Marketplace Artifact for Algeria: Recommendation, Trust, and Monetization in One Mobile Platform
4. Engineering a Trust-Aware and Proximity-Driven Local Commerce System for Algeria

### French
1. Conception et evaluation d'une plateforme de commerce local orientee confiance pour le marche algerien
2. Wino : une plateforme O2O de commerce local integrant proximite, confiance et croissance marchande en Algerie
3. Conception et evaluation d'un systeme mobile de commerce local explicable pour l'Algerie

### Arabic
1. تصميم وتقييم منصة تجارة محلية رقمية موجهة للسوق الجزائري تجمع بين القرب والثقة ونمو التاجر
2. وينو: منصة تجارة محلية O2O قابلة للتفسير للسوق الجزائري

## 8) Recent product evolution that strengthens the memoire
Recent implementation changes improved the academic narrative, not only the UI:
- first-run onboarding now includes visible language choice,
- nearby/location permission education is centralized and reusable,
- merchant ads dashboard now explains what metrics mean more clearly,
- report/review strings were translated more consistently,
- device registration path was cleaned up to one active route,
- user-facing branding is more consistently `Wino`.

These changes matter because they support a stronger narrative around usability, explainability, product maturation, and iterative refinement.

## 9) Suggested academic framing
The strongest memoire framing is a combination of:
- Design Science Research:
  Wino is an artifact built to solve a concrete problem and evaluated through implementation plus measurable outcomes.
- Socio-technical systems thinking:
  the system must fit users, merchants, trust processes, and market context, not just technical correctness.
- O2O local commerce framing:
  the goal is not only online checkout but digitally improving local discovery, confidence, and decision support.

## 10) Suggested academic KPIs
### Recommendation and discovery
- Precision@K / Recall@K / NDCG@K
- search-to-detail conversion
- nearby-to-contact or nearby-to-share conversion
- recommendation CTR

### Trust and moderation
- low-credibility review ratio over time
- effective report ratio
- moderated-item rate
- verified-store interaction lift

### Merchant growth
- merchant activation and retention
- first publish rate
- promotion creation rate
- subscription request completion rate
- merchant understanding of dashboard metrics

### System and operations
- latency/error rate by endpoint family
- notification delivery reliability
- payment-review turnaround time

## 11) Current maturity
The project is no longer a simple CRUD marketplace. It contains:
- local search and nearby logic,
- behavioral tracking,
- trust and abuse mitigation,
- merchant monetization flows,
- multilingual groundwork,
- Android deep-link and notification infrastructure,
- first-run and location education UX work.

This is enough to present Wino as an implemented artifact suitable for a serious memoire.

## 12) Main limitations before production
- development-friendly defaults still exist in server settings
- app base URL is hardcoded locally
- localization is not fully complete across all UI text
- production monitoring and runbooks are still incomplete
- automated coverage needs to grow, especially end-to-end
- OTP flow still needs stronger production hardening
- some branding remnants still exist in internal identifiers/config values
- explainability is improving more quickly for merchants than for end users

These limits should be presented honestly because they strengthen the credibility of the memoire rather than weaken it.

## 13) Stronger source bank for the memoire
### Official and market context
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

10. Algerian tax authority - launch of the online tax-stamp payment platform "Qassimatouka", 2025-03-05
https://www.mfdgi.gov.dz/fr/a-propos/actu-fr/lancement-qassimatouka

11. Algerian tax authority - online payment service for commerce registry stamp duties, 2025-12-24
https://www.mfdgi.gov.dz/fr/a-propos/actu-fr/paiement-des-droits-de-timbre-du-registre-de-commerce-en-ligne

12. Algerian tax authority - launch of the digital platform "Tabioucom", 2024-08-08
https://www.mfdgi.gov.dz/fr/a-propos/actu-fr/lancemant-plateforme-tabioukom-fr

### Academic framing and theory
13. Hevner et al. (2004), Design Science in Information Systems Research
https://aisel.aisnet.org/misq/vol28/iss1/6/

14. Peffers et al. (2007), A Design Science Research Methodology for Information Systems Research
https://doi.org/10.2753/MIS0742-1222240302

15. Baxter and Sommerville (2011), Socio-technical systems: From design methods to systems engineering
https://doi.org/10.1016/j.intcom.2010.07.003

### Recommendation, explainability, trust
16. Zhang and Chen (2020), Explainable Recommendation: A Survey and New Perspectives
https://doi.org/10.1561/1500000066

17. Josang, Ismail, and Boyd (2007), A survey of trust and reputation systems for online service provision
https://doi.org/10.1016/j.dss.2005.05.019

18. Hendrikx, Bubendorfer, and Chard (2015), Reputation systems: A survey and taxonomy
https://doi.org/10.1016/j.jpdc.2014.08.004

19. Dellarocas (2003), The Digitization of Word-of-Mouth: Promise and Challenges of Online Feedback Mechanisms
https://econpapers.repec.org/article/inmormnsc/v_3a49_3ay_3a2003_3ai_3a10_3ap_3a1407-1424.htm

### Emerging markets and Algeria-specific adoption
20. Gupta and Jeyaraj (2021), Online-to-Offline (O2O) Commerce in Emerging Markets: Analysis of the Retail Sector
https://doi.org/10.1080/10599231.2021.1983501

21. Hassen et al. (2020), Factors Influencing the adoption of e-commerce by SMEs in Algeria: a qualitative study
https://doi.org/10.31436/ijpcc.v6i2.147

22. Drivers of E-Commerce Adoption in Algeria (2025), TAM and TPB field study
https://asjp.cerist.dz/en/article/273952

23. Benseddik (2025), Electronic Payment Systems in Algeria
https://asjp.cerist.dz/en/article/265435

24. E-Banking Adoption by Algerian Bank Customers (2023)
https://doi.org/10.4018/IJESMA.317943

## 14) Thesis-writing advice
For the memoire, do not present Wino as "finished e-commerce". Present it as:
- a practical local-commerce artifact,
- already rich enough to evaluate,
- grounded in real market and system constraints,
- and honest about production-readiness limits.

That positioning is academically stronger than overselling it.

## 15) Best companion files
- `Academic-and-Practical-Description.txt`
- `Market-Analysis-Algeria.txt`
- `ALGERIA_COMPETITIVE_ADVANTAGE_PLAN.txt`
- `MEMOIRE_RESEARCH_DOSSIER_2026-03.md`
- `PROJECT_CONTEXT_FOR_AI_AND_MEMOIRE.md`
