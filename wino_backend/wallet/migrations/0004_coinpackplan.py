from django.db import migrations, models


def seed_coin_pack_plans(apps, schema_editor):
    CoinPackPlan = apps.get_model('wallet', 'CoinPackPlan')

    defaults = [
        # Post coin plans
        {
            'coin_type': 'post',
            'pack_id': 'post_100',
            'coins_amount': 100,
            'price_amount': '1000.00',
            'title': 'Starter Posts',
            'sort_order': 10,
            'is_active': True,
        },
        {
            'coin_type': 'post',
            'pack_id': 'post_220',
            'coins_amount': 220,
            'price_amount': '2000.00',
            'title': 'Business Posts',
            'sort_order': 20,
            'is_active': True,
        },
        {
            'coin_type': 'post',
            'pack_id': 'post_480',
            'coins_amount': 480,
            'price_amount': '4000.00',
            'title': 'Power Posts',
            'sort_order': 30,
            'is_active': True,
        },
        # Ad view plans
        {
            'coin_type': 'ad_view',
            'pack_id': 'ad_100',
            'coins_amount': 100,
            'price_amount': '500.00',
            'title': 'Mini Ads',
            'sort_order': 10,
            'is_active': True,
        },
        {
            'coin_type': 'ad_view',
            'pack_id': 'ad_260',
            'coins_amount': 260,
            'price_amount': '1200.00',
            'title': 'Growth Ads',
            'sort_order': 20,
            'is_active': True,
        },
        {
            'coin_type': 'ad_view',
            'pack_id': 'ad_700',
            'coins_amount': 700,
            'price_amount': '3000.00',
            'title': 'Scale Ads',
            'sort_order': 30,
            'is_active': True,
        },
    ]

    for data in defaults:
        CoinPackPlan.objects.update_or_create(
            pack_id=data['pack_id'],
            defaults=data,
        )


class Migration(migrations.Migration):

    dependencies = [
        ('wallet', '0003_coinpurchaseproof'),
    ]

    operations = [
        migrations.CreateModel(
            name='CoinPackPlan',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('coin_type', models.CharField(choices=[('post', 'Post Coins'), ('ad_view', 'Ad View Coins')], max_length=20)),
                ('pack_id', models.SlugField(max_length=80, unique=True)),
                ('coins_amount', models.PositiveIntegerField(default=0)),
                ('price_amount', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('title', models.CharField(blank=True, default='', max_length=120)),
                ('sort_order', models.PositiveIntegerField(default=0)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['coin_type', 'sort_order', 'coins_amount', 'id'],
            },
        ),
        migrations.RunPython(seed_coin_pack_plans, migrations.RunPython.noop),
    ]
