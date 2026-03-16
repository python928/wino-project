# Merchant Subscription, Payment, and Promotions Redesign Blueprint

Date: 2026-03-15
Project: Toprice (Django + Flutter)
Audience: Product, Engineering, Design, Growth, Merchant Operations

## 1. Why This Redesign Is Needed
Current implementation has a strong base, but merchant experience is still operationally heavy and competitively weak in three critical places:
- Plan purchase and payment confirmation is too manual and low-confidence for merchants.
- Promotions and sponsored ads are functional but lack key controls merchants expect (automation, batch actions, ROI clarity).
- Analytics are visible but not decision-ready (limited filtering, no optimization guidance, no conversion story).

This document defines a collaborative target design from three perspectives:
- Senior UI Specialist: clear, practical, trust-building UX for all merchant skill levels.
- Promotions Expert: high-impact, efficient campaign tooling aligned with merchant growth goals.
- Senior Programmer: secure, fast, reliable implementation with measurable outcomes.

## 2. Deep Current-State Snapshot (From Code)

### 2.1 What already works well (keep and build on)
- Subscription feature gating is centralized and enforceable in backend services:
  - `app-backend/subscriptions/services.py`
- Merchant dashboard data is aggregated server-side in one place:
  - `app-backend/subscriptions/services.py` (`build_merchant_dashboard`)
- Payment request with up to 3 proof images already exists:
  - `app-backend/subscriptions/models.py`
  - `app-backend/subscriptions/views.py`
- Promotion engine supports kinds, placements, audience targeting, and impression fields:
  - `app-backend/catalog/models.py`
  - `app-backend/catalog/views.py`
- Flutter screens already cover core flow:
  - Plan and payment: `the_app/lib/presentation/subscription/subscription_plans_screen.dart`
  - Ads dashboard: `the_app/lib/presentation/subscription/ads_dashboard_screen.dart`
  - Create/edit campaign: `the_app/lib/presentation/profile/add_promotion_screen.dart`

### 2.2 Merchant pain points observed in implementation
- Payment status feedback is weak after submission (pending state exists but confidence loop is shallow).
- Payment proof validation is minimal (no explicit file size/type policy enforcement in request flow).
- No SLA timer, no clear expected review time, no event-style status timeline in merchant UI.
- Ads and promotion management lacks bulk actions (pause/resume/duplicate/archive).
- Campaign automation is limited (no budget pacing helper, no auto-stop with actionable suggestions).
- Analytics focus on totals; limited segmentation and no optimization recommendations.
- Date filtering exists, but no quick presets (7d, 14d, 30d, month-to-date), no saved views.
- Campaign objective framing is weak (awareness, traffic, conversions are not first-class UX concepts).

## 3. Competitive Principles (Market-Standard Behaviors)
External references used to shape this plan:
- Stripe subscription lifecycle and status-driven provisioning:
  - https://docs.stripe.com/billing/subscriptions/overview
- Google Ads core interpretation of impressions and CTR:
  - https://support.google.com/google-ads/answer/6320
  - https://support.google.com/google-ads/answer/2615875

Competitive principles to adopt:
- Status-first lifecycle design (draft, pending, approved, active, expired, failed, rejected).
- Event-based merchant communication (notifications at each state transition).
- Decision-ready analytics (show metric definitions and optimization next actions).
- Campaign controls that reduce manual work (templates, presets, bulk operations, automation rules).

## 4. Target Merchant Experience (End-to-End)

### 4.1 Step A: Select Plan
Merchant opens Plans screen and sees:
- Tier cards with feature comparison table (not only separate cards).
- "Best for" tags by merchant profile:
  - New shop
  - Growing catalog
  - High-volume store
- Inline ROI hint for each plan:
  - Example: "If your average margin per sale is X, this plan needs Y extra sales/month to break even."

UI behavior:
- Primary CTA: `Choose plan`
- Secondary CTA: `Compare all plans`
- Always-visible support action: `Need help choosing?`

### 4.2 Step B: Payment Method and Submission
Payment screen becomes a guided 3-step flow with progress header:
1. Confirm plan and amount
2. Transfer and upload proof
3. Review and submit

Must-have UX details:
- Explicit proof requirements shown before upload:
  - accepted formats
  - max size per file
  - max files
- Real-time upload quality checks (blur warning, file too large, unsupported type).
- Merchant gets stable request ID and expected review SLA (for example: "Reviewed within 2-12 hours").
- Payment status card is pinned in app home/profile until resolved.

### 4.3 Step C: Approval and Activation
When admin approves:
- Merchant gets in-app notification and optional email/SMS.
- Subscription status updates immediately.
- Access rights are provisioned automatically (already partially supported by current service layer).
- Merchant sees "You are now on <Plan Name>" summary with unlocked features.

When rejected:
- Merchant sees reason category + guidance:
  - unreadable proof
  - mismatch amount
  - missing transfer reference
- CTA: `Resubmit proof` without repeating full form.

### 4.4 Step D: Create Promotion or Sponsored Ad
Merchant selects objective first:
- Awareness (maximize impressions)
- Traffic (maximize clicks)
- Conversions (future-ready when conversion tracking is added)

Then create campaign via structured form:
- Product selection
- Campaign type (`Discount` or `Sponsored Ad`)
- Audience targeting
- Duration
- Impression limit/budget pacing
- Preview panel before publish

Critical behavior:
- Plan limits shown inline while editing fields.
- If merchant nears limits, show proactive alternatives:
  - shorten duration
  - reduce targeting scope
  - suggest plan upgrade only when truly needed

### 4.5 Step E: Analytics and Optimization
Analytics page has three layers:
- Layer 1: Executive KPIs (Impressions, Clicks, CTR, Active campaigns, Spend, Est. ROI)
- Layer 2: Campaign leaderboard (sortable by CTR, CPC-equivalent, conversion proxy)
- Layer 3: Product insights (top and underperforming products + reasons)

Display method:
- KPI cards with trend arrows vs previous period.
- Date presets and custom range.
- Metric tooltip glossary.
- Recommendation rail ("Try this next") generated from rules.

## 5. Role-by-Role Deliverables

## 5.1 Senior UI Specialist Deliverables
Design system and interaction requirements:
- Build one coherent merchant monetization design language:
  - Consistent card hierarchy
  - Strong state chips (`Pending`, `Approved`, `Rejected`, `Active`, `Expired`)
  - Uniform CTA hierarchy
- Replace long forms with staged flows and sticky action footer.
- Add zero-state and empty-state patterns:
  - No campaigns yet
  - No data for selected period
  - Subscription expired
- Add confidence UX:
  - Request timeline component
  - Validation messages with actionable text
  - Data freshness indicator (last updated timestamp)
- Mobile-first ergonomics:
  - One-thumb reachable actions
  - Avoid dense table-only layouts; use responsive cards + optional table mode

Acceptance criteria for UI:
- New merchant can submit payment proof in under 90 seconds.
- Merchant can create a valid sponsored ad in under 2 minutes.
- At least 90% of validation errors are resolved on first retry.

## 5.2 Promotions Expert Deliverables
Feature set that merchants request most:
- Campaign templates:
  - New arrival boost
  - Weekend flash discount
  - Slow-moving inventory recovery
- Automation rules:
  - Auto-pause campaign when CTR below threshold for N hours
  - Auto-stop at impression cap
  - Auto-remind merchant before campaign end
- Audience intelligence:
  - Quick segments: nearby, repeat buyers, category-interested users, followers
  - Exclusion lists to avoid wasting impressions
- Offer mechanics:
  - Discount laddering (10%, 15%, 20% depending on campaign age)
  - Time windows (peak hours)
  - Promo stacking safeguards
- Performance guidance:
  - Explain why campaign underperformed
  - Suggest next best action with one-click apply

Promotion KPIs:
- Activation rate from created draft to published campaign
- Average CTR by campaign objective
- Cost-per-click proxy (impressions-to-click efficiency)
- Repeat campaign usage per merchant

## 5.3 Senior Programmer Deliverables
Implementation constraints and standards:
- Security:
  - Validate file mime type and file size for proofs server-side.
  - Enforce ownership and access checks at every campaign/payment endpoint.
  - Add rate limiting for payment request submissions and heavy analytics endpoints.
- Reliability:
  - Status transitions must be idempotent.
  - Use atomic transactions for approve/reject flows.
  - Log all status changes with actor and timestamp.
- Performance:
  - Add targeted indexes for campaign date/status queries.
  - Cache dashboard aggregates for short windows (for example 60-180 seconds).
  - Avoid N+1 query patterns with `select_related` and `prefetch_related`.
- Observability:
  - Add structured logs and business metrics counters.
  - Track p95 latency for dashboard API and campaign publish API.

## 6. Recommended Architecture Changes

### 6.1 Backend (Django/DRF)
Add or extend:
- `SubscriptionPaymentRequest` fields:
  - `review_sla_hours` (int)
  - `status_reason_code` (choice)
  - `status_reason_text` (text)
  - `reviewed_by` (FK to admin user)
  - `reviewed_at` (datetime)
- `Promotion` workflow fields:
  - `status` (`draft`, `active`, `paused`, `completed`, `stopped`)
  - `objective` (`awareness`, `traffic`, `conversion_proxy`)
  - `auto_rules` (JSON)

New API contracts:
- `GET /api/subscriptions/payment-requests/{id}/timeline/`
- `POST /api/catalog/promotions/bulk-action/`
- `POST /api/catalog/promotions/{id}/duplicate/`
- `GET /api/subscriptions/merchant-dashboard/insights/`

Service-layer updates:
- Extend `enforce_promotion_constraints` to strictly enforce max impression caps and status transitions.
- Add scheduled task to auto-stop campaigns that hit cap or end date.
- Add recommendation rules engine for optimization tips from KPI patterns.

### 6.2 Flutter App
Refactor UI modules into dedicated flows:
- `payment_request_wizard_screen.dart`
- `payment_request_status_screen.dart`
- `campaign_objective_picker.dart`
- `campaign_editor_screen.dart`
- `analytics_insights_screen.dart`

Provider enhancements:
- Add optimistic state updates for campaign pause/resume.
- Add local draft persistence for campaign form.
- Add retry queue for failed upload or publish actions.

### 6.3 Notifications
Integrate event triggers:
- Payment request created, approved, rejected
- Subscription expiring in 7 days and 1 day
- Campaign nearing end or cap

Channels:
- In-app notifications (existing notifications app)
- Optional email adapter (recommended)

## 7. Analytics Interface Specification

### 7.1 KPI Definitions Block
Show small "i" info tooltip for each metric:
- Impressions: number of times campaign was shown
- Clicks: number of ad clicks
- CTR: clicks / impressions * 100
- Conversion proxy: product actions after click (favorite, message, negotiate)

### 7.2 Required Filters
- Date presets: `Today`, `Last 7 days`, `Last 14 days`, `Last 30 days`, `Month to date`
- Campaign type: `Sponsored Ads`, `Discount Offers`, `All`
- Objective: `Awareness`, `Traffic`, `Conversion Proxy`
- Product category

### 7.3 Merchant-Friendly Insights
Each period should include:
- Top 3 winning campaigns and reasons
- Top 3 weak campaigns and fixes
- One-click actions:
  - duplicate winner
  - pause weak ad
  - increase impressions on high CTR ad

## 8. Prioritized Implementation Roadmap

### Phase 1 (1-2 weeks): Confidence and Control
- Improve payment flow UX and status visibility.
- Add server-side proof validation rules.
- Add status reason on rejection.
- Add analytics date presets and metric glossary.

### Phase 2 (2-3 weeks): Campaign Efficiency
- Add bulk campaign actions.
- Add objective-first campaign creation.
- Add auto-stop at cap and scheduled integrity checks.
- Add recommendations rail in dashboard.

### Phase 3 (2-4 weeks): Competitive Differentiation
- Add campaign templates and automation rules.
- Add conversion proxy metrics and ROI estimates.
- Add notification workflows (in-app + optional email).

## 9. Technical Risks and Mitigations
- Risk: Dashboard query cost grows with merchant data volume.
  - Mitigation: cache strategy + pre-aggregated daily metrics table.
- Risk: Manual admin review bottleneck.
  - Mitigation: SLA tracking + queue dashboard + reason-code macros.
- Risk: Merchants misuse targeting and waste budget.
  - Mitigation: objective presets and guardrails, not free-form defaults.
- Risk: UX complexity increases.
  - Mitigation: progressive disclosure and default templates.

## 10. Success Metrics (90-day)
- +25% increase in paid plan activation completion rate
- -40% reduction in payment-related support messages
- +30% increase in campaign publish rate
- +20% increase in average merchant CTR
- +15% increase in repeat campaign creation per merchant

## 11. Definition of Done
This redesign is complete when:
- Merchant can pay, track, and resolve payment status with clear guidance.
- Merchant can launch, pause, duplicate, and optimize campaigns from one dashboard.
- Analytics answers "what happened" and "what to do next" clearly.
- Backend enforces all constraints safely, with measurable p95 performance and auditable status transitions.

## 12. Immediate Action List for This Repository
1. Create a new payment request timeline endpoint and response schema.
2. Add proof validation (file type, size, count) in `SubscriptionPaymentRequestViewSet.create`.
3. Extend campaign model/service to include explicit campaign status and objective.
4. Add dashboard filter presets and insights API in subscriptions service layer.
5. Split current Flutter plan/payment/ad screens into focused wizard and insights modules.
6. Add notification events for payment and subscription lifecycle states.

---
This blueprint is designed to be implemented incrementally without breaking existing flows, while moving Toprice toward a merchant-grade monetization and promotions system that can compete with stronger marketplace tools.
