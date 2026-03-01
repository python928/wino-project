from django.db import migrations


def seed_payment_config(apps, schema_editor):
	SubscriptionPaymentConfig = apps.get_model('subscriptions', 'SubscriptionPaymentConfig')
	if SubscriptionPaymentConfig.objects.filter(is_active=True).exists():
		return
	SubscriptionPaymentConfig.objects.create(
		rib='00799999004129827780',
		instructions='Send money to this RIB and submit payment confirmation.',
		is_active=True,
	)


class Migration(migrations.Migration):
	dependencies = [
		('subscriptions', '0003_subscriptionpaymentconfig'),
	]

	operations = [
		migrations.RunPython(seed_payment_config, migrations.RunPython.noop),
	]
