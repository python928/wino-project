from django.core.management.base import BaseCommand

from analytics.scoring import update_all_profiles


class Command(BaseCommand):
	help = 'Update interest profiles for all active users based on recent interactions.'

	def handle(self, *args, **options):
		self.stdout.write('Starting profile updates...')
		count = update_all_profiles()
		self.stdout.write(self.style.SUCCESS(f'Successfully updated {count} user profiles.'))
