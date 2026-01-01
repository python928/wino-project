from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APITestCase

from notifications.models import Notification
from stores.models import Follower, Store
from .models import Promotion

User = get_user_model()


class PromotionSignalTests(APITestCase):
	def setUp(self):
		self.owner = User.objects.create_user(username='owner', password='pass1234')
		self.fan = User.objects.create_user(username='fan', password='pass1234')
		self.store = Store.objects.create(owner=self.owner, name='Store')
		Follower.objects.create(user=self.fan, store=self.store)

	def test_promotion_creates_notifications_for_followers(self):
		start = timezone.now()
		end = start + timedelta(days=1)
		Promotion.objects.create(
			store=self.store,
			name='Promo',
			percentage=10,
			start_date=start,
			end_date=end,
		)
		self.assertTrue(Notification.objects.filter(receiver=self.fan, type='promotion').exists())
