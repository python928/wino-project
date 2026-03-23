# Memoire Technical Summary (Wino)

## 1) Problem framing
Wino addresses local commerce friction in Algeria by combining:
- location-aware discovery,
- trust-oriented interaction handling,
- and merchant monetization mechanisms.

## 2) Technical stack
- Backend: Django + DRF + JWT + scoped throttling.
- Mobile client: Flutter (Android-only deployment scope at repository level).
- Notifications: Firebase messaging.
- Background jobs: Celery/Redis (optional depending on deployment mode).

## 3) Core architectural decision
- `Store == User` model unification.

## 4) System modules
- Catalog/search/reviews/favorites.
- Ads campaigns and click registration.
- Wallet with purchase approvals.
- Subscriptions plans + merchant access status.
- Analytics (events, recommendations, trust signals).
- Feedback module.

## 5) Research-relevant contributions
- Hybrid recommendation pipeline usable in production constraints.
- Trust/abuse mitigation layer with credibility scoring.
- Practical monetization integration with operational controls.
- Local O2O adaptation for Algerian market context.

## 6) Operational gaps before production
- Production hardening defaults and secret governance.
- End-to-end observability (errors/traces/APM).
- Wider automated test coverage for critical monetization and trust flows.
- Full localization rollout across all UI text.

## 7) Suggested academic KPIs
- Recommendation quality: Precision@K, Recall@K, NDCG@K.
- Business conversion: CTR, conversion funnel, retention.
- Trust quality: low-credibility report ratio over time.
- System performance: latency and error rate by endpoint group.

## 8) Conclusion
Wino demonstrates an applied architecture that is both academically discussable and commercially actionable, with clear next steps toward production maturity and measurable impact.
