from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from django.urls import reverse
from rest_framework import serializers
from rest_framework import status
from rest_framework.test import APITestCase

from .models import MerchantSubscription, SubscriptionPaymentRequest, SubscriptionPlan
from .services import ensure_can_create_post, get_active_subscription
from wallet.services import get_coin_costs

User = get_user_model()


class SubscriptionPlanTests(APITestCase):
	def setUp(self):
		self.admin = User.objects.create_superuser(username='admin', password='pass1234')

	def test_create_and_list_plan(self):
		create_url = reverse('subscription-plan-list')
		payload = {
			'name': 'Pro',
			'max_products': 100,
			'price': '9.99',
			'duration_days': 30,
		}
		self.client.force_authenticate(user=self.admin)
		res = self.client.post(create_url, payload, format='json')
		self.assertEqual(res.status_code, status.HTTP_201_CREATED)
		self.assertTrue(SubscriptionPlan.objects.filter(name='Pro').exists())

		list_res = self.client.get(create_url)
		self.assertEqual(list_res.status_code, status.HTTP_200_OK)
		names = [item['name'] for item in list_res.data['results']]
		self.assertIn('Pro', names)


class SubscriptionActivationTests(APITestCase):
	def setUp(self):
		self.merchant = User.objects.create_user(username='merchant', password='pass1234', name='Merchant')
		self.plan = SubscriptionPlan.objects.create(
			name='Pro',
			slug='pro-test',
			max_products=100,
			price='1000.00',
			duration_days=30,
			is_active=True,
		)

	def test_approve_payment_request_activates_subscription(self):
		req = SubscriptionPaymentRequest.objects.create(
			merchant=self.merchant,
			plan=self.plan,
			status=SubscriptionPaymentRequest.STATUS_PENDING,
			payment_note='transfer-123',
		)
		req.status = SubscriptionPaymentRequest.STATUS_APPROVED
		req.save(update_fields=['status'])

		sub = get_active_subscription(self.merchant)
		self.assertIsNotNone(sub)
		self.assertEqual(sub.store_id, self.merchant.id)
		self.assertEqual(sub.plan_id, self.plan.id)
		self.assertEqual(sub.status, 'active')

	def test_approved_subscription_allows_post_creation_beyond_free_limit(self):
		costs = get_coin_costs()
		cost = int(costs['product'])
		self.merchant.coins_balance = cost * 2
		self.merchant.save(update_fields=['coins_balance'])

		# Publishing consumes post coins for product create.
		ensure_can_create_post(self.merchant, 'product')
		self.merchant.refresh_from_db()
		self.assertEqual(self.merchant.coins_balance, cost)

		# A second publish with exact remaining budget succeeds.
		ensure_can_create_post(self.merchant, 'product')
		self.merchant.refresh_from_db()
		self.assertEqual(self.merchant.coins_balance, 0)

		# No remaining budget should raise INSUFFICIENT_COINS.
		with self.assertRaises(serializers.ValidationError) as exc:
			ensure_can_create_post(self.merchant, 'product')
		detail = exc.exception.detail
		self.assertEqual(detail.get('code'), 'INSUFFICIENT_COINS')
		self.assertEqual(int(detail.get('required')), cost)
		self.assertEqual(int(detail.get('balance')), 0)

	def test_post_coin_deduction_is_atomic(self):
		costs = get_coin_costs()
		cost = int(costs['product'])
		self.merchant.coins_balance = cost
		self.merchant.save(update_fields=['coins_balance'])

		ensure_can_create_post(self.merchant, 'product')
		self.merchant.refresh_from_db()
		self.assertEqual(self.merchant.coins_balance, 0)
