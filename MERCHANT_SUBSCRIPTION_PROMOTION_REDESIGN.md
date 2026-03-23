# Merchant Subscription, Payment, and Promotions Redesign Blueprint

Date: 2026-03-23
Project: Wino (Django + Flutter)
Audience: Product, Engineering, Design, Growth, Merchant Operations

## 1. Why This Redesign Still Matters
The current implementation now has a stronger base than when this blueprint started, but merchant experience is still operationally heavier than it should be in three places:
- plan purchase and payment confirmation still rely on partial manual review,
- promotions and sponsored ads still need stronger merchant control and ROI guidance,
- analytics are more readable than before, but not fully decision-ready yet.

This document remains a target-state blueprint, updated to reflect what has already improved in code.

## 2. Current-State Snapshot (Updated From Code)

### 2.1 What already works well now
- Subscription plans are exposed through backend router and app config.
- Payment request with up to 3 proof images already exists.
- Merchant dashboard data is aggregated server-side.
- Ads campaigns and click tracking already work.
- Flutter screens exist for subscription plans, payment submission, and ads dashboard.
- Merchant UX recently improved in these areas:
  - clearer empty/error/loading states,
  - stronger localization coverage in subscriptions/dashboard,
  - a “What these numbers mean” explainability card in the ads dashboard.

### 2.2 What still feels weak for merchants
- Payment status confidence loop is still too shallow after submission.
- No strong SLA / expected review-time communication.
- No event-style payment timeline in merchant UI.
- Campaign automation remains limited.
- Merchant KPI interpretation is still stronger than before, but not yet action-oriented enough.
- There is no merchant-facing “next best action” layer.

## 3. Competitive Principles To Keep
External market-standard principles that still apply:
- status-first lifecycle design
- event-based merchant communication
- decision-ready analytics
- confidence-building payment UX
- clear objectives, not raw counters only

## 4. What Changed Since The Previous Draft
The blueprint should now acknowledge that some recommended work is already partially implemented:

### Already improved
- better merchant copy in subscription and dashboard screens
- clearer loading and empty states
- better localization for dashboard/payment strings
- stronger explainability in dashboard UI

### Still missing
- payment timeline / SLA communication
- campaign bulk actions
- ROI storytelling beyond totals
- objective-based promotion guidance
- stronger merchant notifications for lifecycle changes

## 5. Target Merchant Experience (Revised)
### 5.1 Step A: Select Plan
The merchant should see:
- plan name
- benefits
- access impact
- what happens next after submission

### 5.2 Step B: Submit Payment Proof
The merchant should see:
- accepted proof rules
- expected review time
- current status
- reassurance that access will update after review

### 5.3 Step C: Track Approval
The merchant should have:
- timeline of submission / review / approval / rejection
- admin note if rejected
- clear retry path

### 5.4 Step D: Promote Content
The merchant should understand:
- what type of content to promote
- what audience or local scope is appropriate
- what success metric matters for this campaign

### 5.5 Step E: Read Results
The dashboard should answer:
- what happened?
- why does it matter?
- what should the merchant do next?

## 6. Product and Engineering Priorities
### Priority 1
- status timeline for payment requests
- expected review-time message
- merchant notifications on lifecycle changes

### Priority 2
- campaign quick actions: pause, resume, duplicate, archive
- date presets and summary filters
- clearer KPI glossary for all monetization views

### Priority 3
- recommendations for content promotion
- ROI hints and decision support
- lighter merchant onboarding into subscriptions/ads

## 7. Backend Suggestions
- keep payment request status transitions explicit and auditable
- expose timeline/history endpoint consistently where needed
- attach structured reason/admin note on rejection
- keep alias compatibility only where it reduces migration risk

## 8. Flutter Suggestions
- keep subscription/payment/dashboard copy localized through ARB first when possible
- extend the current explainability-card pattern to more monetization screens
- use shared status chips and lifecycle UI instead of one-off labels
- maintain consistency between subscription, wallet, and ads flows

## 9. Success Metrics (90-day)
- payment submission completion rate
- payment resubmission rate after rejection
- merchant activation into first campaign
- merchant understanding of dashboard KPIs
- repeat promotion behavior

## 10. Practical Conclusion
This redesign is no longer a greenfield plan. It is now a mixed roadmap:
- part of it is already reflected in the code,
- part of it remains an implementation backlog,
- and its next stage should focus less on raw UI polish and more on merchant confidence and decision support.
