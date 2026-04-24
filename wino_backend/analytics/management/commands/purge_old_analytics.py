from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from analytics.models import InteractionLog
from users.models import AbuseFlag, TrustSettings


class Command(BaseCommand):
    help = 'Purge old analytics and abuse signal rows based on TrustSettings retention policy.'

    def handle(self, *args, **options):
        trust = TrustSettings.get_settings()
        retention_days = int(getattr(trust, 'analytics_retention_days', 180) or 180)
        cutoff = timezone.now() - timedelta(days=retention_days)

        deleted_logs, _ = InteractionLog.objects.filter(timestamp__lt=cutoff).delete()
        deleted_flags, _ = AbuseFlag.objects.filter(last_seen_at__lt=cutoff).delete()

        self.stdout.write(
            self.style.SUCCESS(
                f'Purged analytics older than {retention_days} days: logs={deleted_logs}, abuse_flags={deleted_flags}'
            )
        )
