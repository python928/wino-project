from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0008_productreport_evidence_snapshot_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='category',
            name='name_ar',
            field=models.CharField(blank=True, default='', max_length=255),
        ),
        migrations.AddField(
            model_name='category',
            name='name_en',
            field=models.CharField(blank=True, default='', max_length=255),
        ),
        migrations.AddField(
            model_name='category',
            name='name_fr',
            field=models.CharField(blank=True, default='', max_length=255),
        ),
    ]
