from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from django.urls import reverse
from rest_framework import serializers
from rest_framework import status
from rest_framework.test import APITestCase

from catalog.models import Product
from .models import MerchantSubscription, SubscriptionPaymentRequest, SubscriptionPlan
from .services import ensure_can_create_post, get_active_subscription

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
		# Free limit is 5; create 6 products to exceed it.
		for i in range(6):
			Product.objects.create(
				store=self.merchant,
				name=f'P{i}',
				price='10.00',
			)

		with self.assertRaises(serializers.ValidationError):
			ensure_can_create_post(self.merchant)

		MerchantSubscription.objects.create(
			store=self.merchant,
			plan=self.plan,
			start_date=timezone.now() - timedelta(days=1),
			end_date=timezone.now() + timedelta(days=30),
			status='active',
		)

		# Should not raise after active subscription exists.
		ensure_can_create_post(self.merchant)
