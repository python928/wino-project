from django.db import migrations


def seed_plans(apps, schema_editor):
	SubscriptionPlan = apps.get_model('subscriptions', 'SubscriptionPlan')
	plans = [
		{
			'name': 'Starter Plan',
			'slug': 'starter',
			'max_products': 25,
			'price': '10000.00',
			'duration_days': 30,
			'benefits': 'Up to 25 posts per month\nPriority review for approval\nBasic support',
			'is_active': True,
		},
		{
			'name': 'Business Plan',
			'slug': 'business',
			'max_products': 80,
			'price': '10000.00',
			'duration_days': 30,
			'benefits': 'Up to 80 posts per month\nPriority listing boost\nFaster support',
			'is_active': True,
		},
		{
			'name': 'Pro Plan',
			'slug': 'pro',
			'max_products': 200,
			'price': '10000.00',
			'duration_days': 30,
			'benefits': 'Up to 200 posts per month\nTop exposure slots\nVIP support',
			'is_active': True,
		},
	]
	for plan in plans:
		SubscriptionPlan.objects.update_or_create(slug=plan['slug'], defaults=plan)


class Migration(migrations.Migration):
	dependencies = [
		('subscriptions', '0001_initial'),
	]

	operations = [
		migrations.RunPython(seed_plans, migrations.RunPython.noop),
	]
