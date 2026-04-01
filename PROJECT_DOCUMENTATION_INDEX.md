# Project Documentation Index

Last updated: 2026-04-01

This file tells you which document to open first depending on what you are trying to understand.

## 0) Canonical status rule
If you want the honest current stage of the project, open:
- `TRANSFORMATION_COMPLETE_SUMMARY.md`

That file is now the single source of truth for wording such as:
- technical POC,
- MVP readiness,
- pilot readiness,
- production readiness.

Short version:
- Wino is technically substantial and much stronger than before.
- The UI/UX transformation is real and large.
- Multilingual support (English, French, Arabic) now covers all core user journeys.
- External Google Maps directions are integrated with proper recovery fallbacks.
- The product is still best described as advanced pre-production / pilot-ready direction, not full production release.

## 1) Best reading order for a new contributor or AI assistant
1. `PROJECT_DOCUMENTATION_INDEX.md`
2. `TRANSFORMATION_COMPLETE_SUMMARY.md`
3. `CODEBASE_MAP_FOR_AI.md`
4. `API_LINKS_EXPLAINED.txt`
5. `APP_LIB_STRUCTURE.txt`
6. `SERVER_STRUCTURE.txt`
7. `MISSING_NOW_AND_NEXT_ACTIONS.txt`
8. `PROJECT_CONTEXT_FOR_AI_AND_MEMOIRE.md`
9. `Academic-and-Practical-Description.txt`
10. `MEMOIRE_TECHNICAL_SUMMARY_2026-03.md`
11. `MEMOIRE_RESEARCH_DOSSIER_2026-03.md`
12. `Market-Analysis-Algeria.txt`
13. `ALGERIA_COMPETITIVE_ADVANTAGE_PLAN.txt`
14. `WINO_POC.md`
15. `WINO_MVP.md`
16. `WINO_BMC.md`
17. `WINO_BUSINESS_PLAN.md`

## 2) Which file answers which question?
### What is this project academically and practically?
- `Academic-and-Practical-Description.txt`
- `MEMOIRE_TECHNICAL_SUMMARY_2026-03.md`

### What is the real current status of the project?
- `TRANSFORMATION_COMPLETE_SUMMARY.md`
- `MISSING_NOW_AND_NEXT_ACTIONS.txt`
- `WINO_POC.md`
- `WINO_MVP.md`

### What problem is Wino solving in Algeria?
- `Market-Analysis-Algeria.txt`
- `ALGERIA_COMPETITIVE_ADVANTAGE_PLAN.txt`
- `WINO_POC.md`
- `WINO_BUSINESS_PLAN.md`

### Where are the APIs and what are the routes?
- `API_LINKS_EXPLAINED.txt`
- `CODEBASE_MAP_FOR_AI.md`

### How is the Flutter app organized?
- `APP_LIB_STRUCTURE.txt`
- `AI_EDITING_GUIDE_FOR_WINO.md`

### How is the repository/backend organized?
- `SERVER_STRUCTURE.txt`
- `CODEBASE_MAP_FOR_AI.md`

### What is still missing or risky?
- `MISSING_NOW_AND_NEXT_ACTIONS.txt`
- `WINO_POC.md`
- `WINO_MVP.md`

### How should an AI assistant edit this repo safely?
- `AI_EDITING_GUIDE_FOR_WINO.md`
- `CODEBASE_MAP_FOR_AI.md`
- `AI_PROGRAMMING_CONTEXT.md`

### What should I use for university writing / memoire work?
- `MEMOIRE_RESEARCH_DOSSIER_2026-03.md`
- `Academic-and-Practical-Description.txt`
- `MEMOIRE_TECHNICAL_SUMMARY_2026-03.md`
- `PROJECT_CONTEXT_FOR_AI_AND_MEMOIRE.md`

### What should I use for product, strategy, and launch planning?
- `WINO_POC.md`
- `WINO_MVP.md`
- `WINO_BMC.md`
- `WINO_BUSINESS_PLAN.md`
- `MERCHANT_SUBSCRIPTION_PROMOTION_REDESIGN.md`

## 3) Recommended doc bundles by use case
### For programming
- `TRANSFORMATION_COMPLETE_SUMMARY.md`
- `CODEBASE_MAP_FOR_AI.md`
- `API_LINKS_EXPLAINED.txt`
- `APP_LIB_STRUCTURE.txt`
- `AI_EDITING_GUIDE_FOR_WINO.md`
- `AI_PROGRAMMING_CONTEXT.md`

### For memoire / university writing
- `TRANSFORMATION_COMPLETE_SUMMARY.md`
- `MEMOIRE_RESEARCH_DOSSIER_2026-03.md`
- `Academic-and-Practical-Description.txt`
- `MEMOIRE_TECHNICAL_SUMMARY_2026-03.md`
- `Market-Analysis-Algeria.txt`
- `ALGERIA_COMPETITIVE_ADVANTAGE_PLAN.txt`
- `PROJECT_CONTEXT_FOR_AI_AND_MEMOIRE.md`

### For product / business planning
- `TRANSFORMATION_COMPLETE_SUMMARY.md`
- `WINO_POC.md`
- `WINO_MVP.md`
- `WINO_BMC.md`
- `WINO_BUSINESS_PLAN.md`
- `Market-Analysis-Algeria.txt`
- `MERCHANT_SUBSCRIPTION_PROMOTION_REDESIGN.md`

### For release / planning
- `TRANSFORMATION_COMPLETE_SUMMARY.md`
- `MISSING_NOW_AND_NEXT_ACTIONS.txt`
- `SERVER_STRUCTURE.txt`
- `WEB_SERVER_AND_ANDROID_LIBS_FEATURES.txt`
- `MERCHANT_SUBSCRIPTION_PROMOTION_REDESIGN.md`

## 4) Maintenance rule
When the codebase changes significantly in any of these areas, update the matching docs in the same workstream:
- endpoints
- routing
- platform scope
- trust/analytics/monetization architecture
- localization strategy
- onboarding / nearby UX
- public branding assumptions
- overall project stage wording in `TRANSFORMATION_COMPLETE_SUMMARY.md`
