# Memoire Technical Summary (Wino)

Last updated: 2026-03-23

## 1) Problem framing
Wino addresses a practical Algerian O2O commerce problem:
- users need nearby and trustworthy discovery,
- merchants need simple growth tools,
- and the system must work even when payment and logistics are not fully automated.

## 2) Technical stack
- Backend: Django + DRF + JWT + scoped throttling
- Mobile client: Flutter + Provider
- Notifications: Firebase Messaging + flutter_local_notifications
- Deep links: short links + custom schemes
- Optional ops stack: Celery + Redis

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

## 6) Current maturity
The project is no longer a simple CRUD marketplace. It contains:
- local search and nearby logic,
- behavioral tracking,
- trust/abuse mitigation,
- merchant monetization flows,
- multilingual groundwork,
- Android deep-link and notification infrastructure.

## 7) Main limitations before production
- development-friendly defaults still exist in server settings
- app base URL is hardcoded locally
- localization is not fully complete across all UI text
- production monitoring and runbooks are still incomplete
- automated coverage needs to grow, especially end-to-end

## 8) Suggested academic KPIs
- Precision@K / Recall@K / NDCG@K for recommendations
- conversion from search/nearby to contact/share
- merchant activation and retention
- low-credibility report ratio over time
- latency/error rate by endpoint family

## 9) Conclusion
Wino is academically valuable because it combines recommendation, trust, and monetization in one applied local-commerce architecture. It is practically valuable because the implemented flows already reflect real market constraints rather than idealized e-commerce assumptions.
