from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0006_remove_promotion_target_user_ids'),
        ('ads', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='adcampaign',
            name='pack',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=models.SET_NULL,
                related_name='ad_campaigns',
                to='catalog.pack',
            ),
        ),
    ]
