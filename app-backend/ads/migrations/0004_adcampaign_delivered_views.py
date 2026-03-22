from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ads', '0003_remove_adcampaign_priority_boost'),
    ]

    operations = [
        migrations.AddField(
            model_name='adcampaign',
            name='delivered_views_count',
            field=models.PositiveIntegerField(default=0),
        ),
    ]
