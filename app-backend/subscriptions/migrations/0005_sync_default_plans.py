from django.db import migrations

from subscriptions.constants import DEFAULT_SUBSCRIPTION_PLANS


def sync_default_plans(apps, schema_editor):
	SubscriptionPlan = apps.get_model('subscriptions', 'SubscriptionPlan')
	for plan in DEFAULT_SUBSCRIPTION_PLANS:
		SubscriptionPlan.objects.update_or_create(
			slug=plan['slug'],
			defaults=plan,
		)


class Migration(migrations.Migration):
	dependencies = [
		('subscriptions', '0004_seed_payment_config'),
	]

	operations = [
		migrations.RunPython(sync_default_plans, migrations.RunPython.noop),
	]
