from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('wallet', '0005_unified_coins_and_pack_promotions'),
    ]

    operations = [
        migrations.AlterField(
            model_name='coinpackplan',
            name='coin_type',
            field=models.CharField(
                blank=True,
                choices=[('post', 'Post Coins'), ('ad_view', 'Ad View Coins')],
                default='post',
                max_length=20,
            ),
        ),
    ]
