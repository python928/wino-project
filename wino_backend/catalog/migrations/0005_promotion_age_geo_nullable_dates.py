"""
Migration: add age targeting, geo_mode + radius, make start/end_date nullable,
remove target_user_ids from DB (kept as blank JSON for backward compat via default).
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0004_promotion_audience_mode_promotion_clicks_count_and_more'),
    ]

    operations = [
        # Age targeting
        migrations.AddField(
            model_name='promotion',
            name='age_from',
            field=models.PositiveIntegerField(
                blank=True,
                null=True,
                help_text='Minimum viewer age (inclusive). Null = no limit.',
            ),
        ),
        migrations.AddField(
            model_name='promotion',
            name='age_to',
            field=models.PositiveIntegerField(
                blank=True,
                null=True,
                help_text='Maximum viewer age (inclusive). Null = no limit.',
            ),
        ),
        # Geographic mode
        migrations.AddField(
            model_name='promotion',
            name='geo_mode',
            field=models.CharField(
                choices=[
                    ('all', 'All Algeria'),
                    ('wilaya', 'Specific Wilayas'),
                    ('radius', 'Radius (km)'),
                ],
                default='all',
                max_length=10,
            ),
        ),
        migrations.AddField(
            model_name='promotion',
            name='target_radius_km',
            field=models.PositiveIntegerField(
                blank=True,
                null=True,
                help_text='Radius in km from store location (used when geo_mode=radius).',
            ),
        ),
        # Make start_date / end_date optional
        migrations.AlterField(
            model_name='promotion',
            name='start_date',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AlterField(
            model_name='promotion',
            name='end_date',
            field=models.DateTimeField(blank=True, null=True),
        ),
        # Remove AUDIENCE_CUSTOM choice (data preserved, choice restricted)
        migrations.AlterField(
            model_name='promotion',
            name='audience_mode',
            field=models.CharField(
                choices=[
                    ('all', 'All'),
                    ('followers', 'Followers'),
                    ('nearby', 'Nearby'),
                    ('wilaya', 'Wilaya'),
                ],
                default='all',
                max_length=20,
            ),
        ),
    ]
