"""No-op catalog migration.

Historically `catalog/migrations/0001_initial.py` was checked in empty and the
real schema landed in `0002_initial.py`. The schema has been moved back into
`0001_initial.py` so other apps can safely depend on `catalog.__first__`.

This migration is intentionally kept as a no-op to avoid renumbering churn.
"""

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0001_initial'),
    ]

    operations = []
