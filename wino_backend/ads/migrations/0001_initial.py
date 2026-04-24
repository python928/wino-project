from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('catalog', '0006_remove_promotion_target_user_ids'),
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='AdCampaign',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255)),
                ('description', models.TextField(blank=True)),
                ('percentage', models.DecimalField(decimal_places=2, default=0.0, max_digits=5)),
                ('placement', models.CharField(choices=[('home_top', 'Home Top'), ('home_feed', 'Home Feed'), ('search_top', 'Search Top')], default='home_top', max_length=20)),
                ('audience_mode', models.CharField(choices=[('all', 'All'), ('followers', 'Followers'), ('nearby', 'Nearby'), ('wilaya', 'Wilaya')], default='all', max_length=20)),
                ('age_from', models.PositiveIntegerField(blank=True, null=True)),
                ('age_to', models.PositiveIntegerField(blank=True, null=True)),
                ('geo_mode', models.CharField(choices=[('all', 'All Algeria'), ('wilaya', 'Specific Wilayas'), ('radius', 'Radius (km)')], default='all', max_length=10)),
                ('target_wilayas', models.JSONField(blank=True, default=list)),
                ('target_radius_km', models.PositiveIntegerField(blank=True, null=True)),
                ('target_categories', models.JSONField(blank=True, default=list)),
                ('priority_boost', models.IntegerField(default=0)),
                ('is_active', models.BooleanField(default=True)),
                ('start_date', models.DateTimeField(blank=True, null=True)),
                ('end_date', models.DateTimeField(blank=True, null=True)),
                ('max_impressions', models.PositiveIntegerField(blank=True, null=True)),
                ('unique_viewers_count', models.PositiveIntegerField(default=0)),
                ('impressions_count', models.PositiveIntegerField(default=0)),
                ('clicks_count', models.PositiveIntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('product', models.ForeignKey(blank=True, null=True, on_delete=models.SET_NULL, related_name='ad_campaigns', to='catalog.product')),
                ('store', models.ForeignKey(on_delete=models.CASCADE, related_name='ad_campaigns', to='users.user')),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='AdCampaignViewer',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('viewer_key', models.CharField(db_index=True, max_length=128)),
                ('first_seen_at', models.DateTimeField(auto_now_add=True)),
                ('last_seen_at', models.DateTimeField(auto_now=True)),
                ('campaign', models.ForeignKey(on_delete=models.CASCADE, related_name='viewer_hits', to='ads.adcampaign')),
            ],
            options={
                'unique_together': {('campaign', 'viewer_key')},
            },
        ),
    ]
