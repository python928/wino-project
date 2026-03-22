from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ads', '0004_adcampaign_delivered_views'),
    ]

    operations = [
        migrations.AddField(
            model_name='adcampaign',
            name='display_hour',
            field=models.PositiveSmallIntegerField(default=12),
        ),
    ]
