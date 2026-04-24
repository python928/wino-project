from django.apps import AppConfig


class AnalyticsConfig(AppConfig):
	default_auto_field = 'django.db.models.BigAutoField'
	name = 'analytics'
	verbose_name = 'Analytics & Recommendations'

	def ready(self):
		try:
			from analytics.signals import _connect_signals
			_connect_signals()
		except Exception:
			pass
