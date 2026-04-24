from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
	initial = True

	dependencies = [
		migrations.swappable_dependency(settings.AUTH_USER_MODEL),
	]

	operations = [
		migrations.CreateModel(
			name='CoinTransaction',
			fields=[
				('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
				('coin_type', models.CharField(choices=[('POST', 'Post Coins'), ('AD_VIEW', 'Ad View Coins')], max_length=10)),
				('amount_signed', models.IntegerField(help_text='Signed change in coin balance.')),
				('reason', models.CharField(blank=True, default='', max_length=120)),
				('related_model', models.CharField(blank=True, default='', max_length=120)),
				('related_id', models.PositiveIntegerField(blank=True, null=True)),
				('created_at', models.DateTimeField(auto_now_add=True)),
				('user', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='coin_transactions', to=settings.AUTH_USER_MODEL)),
			],
			options={'ordering': ['-created_at']},
		),
		migrations.CreateModel(
			name='CoinPurchase',
			fields=[
				('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
				('coin_type', models.CharField(choices=[('POST', 'Post Coins'), ('AD_VIEW', 'Ad View Coins')], max_length=10)),
				('pack_id', models.CharField(blank=True, default='', max_length=80)),
				('coins_amount', models.PositiveIntegerField(default=0)),
				('price_amount', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
				('status', models.CharField(choices=[('pending', 'Pending'), ('completed', 'Completed'), ('failed', 'Failed')], default='pending', max_length=20)),
				('created_at', models.DateTimeField(auto_now_add=True)),
				('user', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='coin_purchases', to=settings.AUTH_USER_MODEL)),
			],
			options={'ordering': ['-created_at']},
		),
	]
