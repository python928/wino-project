# diagrams_2 (PlantUML)

This folder contains per-app DB and Class diagrams in PlantUML format.

## Structure
- db/: DB diagrams
- class/: Class diagrams

Each folder contains:
- users_app.puml
- catalog_app.puml
- ads_app.puml
- analytics_app.puml
- notifications_app.puml
- feedback_app.puml
- subscriptions_app.puml
- wallet_app.puml

## Notes
- Diagrams mirror the current Django models under `app-backend/*/models.py`.
- External app references are shown in an `External` package.
- `class/` diagrams use UML-style attributes, operations, and associations.
- `db/` diagrams use table-style entities with PK/FK columns and explicit cardinalities.
