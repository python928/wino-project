from django.contrib.auth import get_user_model
from django.test import TestCase

from users.models import StoreReport, TrustSettings
from users.trust_scoring import score_store_report


User = get_user_model()


class TrustScoringTests(TestCase):
    def setUp(self):
        self.reporter = User.objects.create_user(username='reporter', password='pass1234')
        self.store = User.objects.create_user(username='store1', password='pass1234')
        TrustSettings.get_settings()

    def test_score_store_report_returns_valid_bounds(self):
        result = score_store_report(self.reporter, self.store)
        self.assertGreaterEqual(result.score, 0)
        self.assertLessEqual(result.score, 100)
        self.assertIn(result.level, ['low', 'medium', 'high'])
        self.assertIsInstance(result.evidence_snapshot, dict)

    def test_store_report_defaults_include_seriousness_fields(self):
        report = StoreReport.objects.create(
            reporter=self.reporter,
            store=self.store,
            reason=StoreReport.REASON_SPAM,
            details='test',
        )
        self.assertEqual(report.seriousness_score, 0)
        self.assertEqual(report.seriousness_level, StoreReport.LEVEL_LOW)
        self.assertTrue(report.is_low_credibility)
