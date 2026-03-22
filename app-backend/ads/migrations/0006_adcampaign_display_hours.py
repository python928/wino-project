from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('ads', '0005_adcampaign_display_hour'),
    ]

    operations = [
        migrations.AddField(
            model_name='adcampaign',
            name='display_hours',
            field=models.JSONField(blank=True, default=list),
        ),
    ]
