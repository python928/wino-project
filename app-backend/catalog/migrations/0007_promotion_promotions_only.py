from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0006_remove_promotion_target_user_ids'),
    ]

    operations = [
        migrations.RemoveField(model_name='promotion', name='kind'),
        migrations.RemoveField(model_name='promotion', name='placement'),
        migrations.RemoveField(model_name='promotion', name='audience_mode'),
        migrations.RemoveField(model_name='promotion', name='age_from'),
        migrations.RemoveField(model_name='promotion', name='age_to'),
        migrations.RemoveField(model_name='promotion', name='geo_mode'),
        migrations.RemoveField(model_name='promotion', name='target_wilayas'),
        migrations.RemoveField(model_name='promotion', name='target_radius_km'),
        migrations.RemoveField(model_name='promotion', name='target_categories'),
        migrations.RemoveField(model_name='promotion', name='priority_boost'),
        migrations.RemoveField(model_name='promotion', name='max_impressions'),
        migrations.RemoveField(model_name='promotion', name='unique_viewers_count'),
        migrations.RemoveField(model_name='promotion', name='impressions_count'),
        migrations.RemoveField(model_name='promotion', name='clicks_count'),
    ]
