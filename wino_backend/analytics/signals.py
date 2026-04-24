"""
================================================================================
analytics/signals.py
================================================================================
ربط تلقائي بين أحداث catalog (Favorite, Review) ونظام التسجيل Analytics.

كيف يعمل:
  - عند حفظ Favorite جديد   → يُسجَّل حدث 'favorite'
  - عند كتابة Review جديد   → يُسجَّل حدث 'contact' (مع rating في metadata)

الشرط: يجب أن تكون موديلات Favorite و Review موجودة في catalog.
الإعداد: يتم تحميل هذا الملف تلقائيًا من analytics/apps.py عبر ready().

إذا لم تكن موديلات catalog جاهزة، هذا الملف يفشل بصمت.
================================================================================
"""

import logging

logger = logging.getLogger(__name__)


def _connect_signals():
	"""
	محاولة ربط الـ signals بشكل آمن.
	تُستدعى من AnalyticsConfig.ready() فقط.
	"""
	try:
		from django.db.models.signals import post_save
		from django.dispatch import receiver
		from analytics.utils import log_user_event

		# ── Favorite signal ──────────────────────────────────────────────────
		try:
			from catalog.models import Favorite

			def _on_favorite_created(sender, instance, created, **kwargs):
				# Favorites are logged in the API view (with discovery metadata)
				# to support correct attribution and avoid double-counting.
				return

			post_save.connect(_on_favorite_created, sender=Favorite, weak=False, dispatch_uid='analytics_favorite')
			logger.info('Analytics: Favorite signal connected.')
		except ImportError:
			logger.warning('Analytics: catalog.Favorite not found — signal skipped.')

		# ── Review signal ─────────────────────────────────────────────────────
		try:
			from catalog.models import Review

			def _on_review_created(sender, instance, created, **kwargs):
				if created and getattr(instance, 'product', None):
					log_user_event(
						user=instance.user,
						action='contact',
						product=instance.product,
						metadata={'rating': getattr(instance, 'rating', None)},
					)

			post_save.connect(_on_review_created, sender=Review, weak=False, dispatch_uid='analytics_review')
			logger.info('Analytics: Review signal connected.')
		except ImportError:
			logger.warning('Analytics: catalog.Review not found — signal skipped.')

	except Exception as e:
		logger.error(f'Analytics signals setup failed: {e}')