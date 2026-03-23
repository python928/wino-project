# Memoire Technical Summary (Wino)

Last updated: 2026-03-23

## 1) Problem framing
Wino addresses a practical Algerian O2O commerce problem:
- users need nearby and trustworthy discovery,
- merchants need simple growth tools,
- and the system must work even when payment and logistics are not fully automated.

The project is therefore not just a marketplace UI; it is an applied socio-technical system where geography, trust, monetization, and UX clarity interact.

## 2) Technical stack
- Backend: Django + DRF + JWT + filtering + scoped throttling
- Mobile client: Flutter + Provider/ChangeNotifier
- Notifications: Firebase Messaging + `flutter_local_notifications`
- Deep links: short links + custom schemes
- Optional ops stack: Celery + Redis
- Localization: ARB/generated strings + runtime translation bridge

## 3) Core architectural choice
- `Store == User`

This reduces domain duplication and keeps store, auth, profile, trust, and monetization flows tightly aligned.

## 4) Main implemented modules
- Catalog: products, promotions, packs, reviews, favorites
- Trust: product/store reports, review credibility, abuse flags, trust settings
- Analytics: events, trust signals, recommendations, interest profiles
- Monetization: ads, wallet, subscriptions, payment proof workflows
- Feedback: user feedback with admin review
- Notifications and deep links

## 5) Research-relevant contributions
1. A hybrid recommendation pipeline grounded in real interaction logs.
2. A credibility/moderation layer that scores reports and reviews instead of treating all signals equally.
3. A local-market architecture adapted to Algerian constraints:
   - proximity
   - direct contact
   - trust deficit
   - partial/manual payment operations
4. A practical integration of monetization inside the same platform.
5. A live example of progressive explainability inside merchant UX.

## 6) Recent product evolution that strengthens the memoire
Recent implementation changes improved the academic story, not only the UI:
- first-run onboarding now includes visible language choice,
- nearby/location permission education is centralized and reusable,
- merchant ads dashboard now explains what metrics mean,
- report/review strings were translated more consistently,
- device registration path was cleaned up to one active route,
- user-facing branding is more consistently `Wino`.

These changes matter because they support a stronger narrative around usability, explainability, and product maturation.

## 7) Suggested academic framing
The best fit is a combination of:
- Design Science Research: Wino is an artifact built to solve a concrete problem.
- Socio-technical systems thinking: the system must fit users, merchants, trust, and market context.
- O2O local commerce framing: the goal is not only online checkout, but better local decision support.

## 8) Suggested academic KPIs
- Precision@K / Recall@K / NDCG@K for recommendations
- conversion from search/nearby to contact/share
- merchant activation and retention
- low-credibility report ratio over time
- dashboard comprehension / decision confidence in merchant UX
- latency/error rate by endpoint family

## 9) Current maturity
The project is no longer a simple CRUD marketplace. It contains:
- local search and nearby logic,
- behavioral tracking,
- trust/abuse mitigation,
- merchant monetization flows,
- multilingual groundwork,
- Android deep-link and notification infrastructure,
- first-run and location education UX work.

## 10) Main limitations before production
- development-friendly defaults still exist in server settings
- app base URL is hardcoded locally
- localization is not fully complete across all UI text
- production monitoring and runbooks are still incomplete
- automated coverage needs to grow, especially end-to-end
- some branding remnants still exist in internal identifiers/config values

## 11) Thesis-writing advice
For the memoire, do not present Wino as “finished e-commerce”. Present it as:
- a practical local-commerce artifact,
- already rich enough to evaluate,
- but still honest about production-readiness limits.

That positioning is academically stronger than overselling it.

## 12) Best companion files
- `Academic-and-Practical-Description.txt`
- `Market-Analysis-Algeria.txt`
- `ALGERIA_COMPETITIVE_ADVANTAGE_PLAN.txt`
- `MEMOIRE_RESEARCH_DOSSIER_2026-03.md`
