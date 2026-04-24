from django.db import migrations


class Migration(migrations.Migration):
	dependencies = [
		('ads', '0002_adcampaign_pack'),
	]

	operations = [
		migrations.RemoveField(
			model_name='adcampaign',
			name='priority_boost',
		),
	]
