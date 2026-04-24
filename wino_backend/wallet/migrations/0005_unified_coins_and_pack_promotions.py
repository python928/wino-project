from django.db import migrations, models
from django.db.models import F


def backfill_unified_balance(apps, schema_editor):
    User = apps.get_model('users', 'User')
    User.objects.update(coins_balance=F('post_coins') + F('ad_view_coins'))


def seed_big_budget_promotions(apps, schema_editor):
    CoinPackPlan = apps.get_model('wallet', 'CoinPackPlan')

    CoinPackPlan.objects.filter(pack_id='post_480').update(
        original_price_amount='4800.00',
        is_promoted=True,
        promo_badge='Big Budget',
    )
    CoinPackPlan.objects.filter(pack_id='ad_700').update(
        original_price_amount='3850.00',
        is_promoted=True,
        promo_badge='Big Budget',
    )

    # Add additional large campaign plans with visible savings.
    CoinPackPlan.objects.update_or_create(
        pack_id='post_1000',
        defaults={
            'coin_type': 'post',
            'coins_amount': 1000,
            'price_amount': '8500.00',
            'original_price_amount': '10000.00',
            'title': 'Enterprise Posts',
            'promo_badge': 'Save 15%',
            'is_promoted': True,
            'sort_order': 40,
            'is_active': True,
        },
    )
    CoinPackPlan.objects.update_or_create(
        pack_id='ad_1500',
        defaults={
            'coin_type': 'ad_view',
            'coins_amount': 1500,
            'price_amount': '6000.00',
            'original_price_amount': '7500.00',
            'title': 'Enterprise Ads',
            'promo_badge': 'Save 20%',
            'is_promoted': True,
            'sort_order': 40,
            'is_active': True,
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0003_user_coins_balance'),
        ('wallet', '0004_coinpackplan'),
    ]

    operations = [
        migrations.AddField(
            model_name='coinpackplan',
            name='is_promoted',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='coinpackplan',
            name='original_price_amount',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True),
        ),
        migrations.AddField(
            model_name='coinpackplan',
            name='promo_badge',
            field=models.CharField(blank=True, default='', max_length=60),
        ),
        migrations.RunPython(backfill_unified_balance, migrations.RunPython.noop),
        migrations.RunPython(seed_big_budget_promotions, migrations.RunPython.noop),
    ]
