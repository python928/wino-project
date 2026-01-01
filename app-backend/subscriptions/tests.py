from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import SubscriptionPlan

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
		self.assertEqual(SubscriptionPlan.objects.count(), 1)

		list_res = self.client.get(create_url)
		self.assertEqual(list_res.status_code, status.HTTP_200_OK)
		self.assertEqual(list_res.data['results'][0]['name'], 'Pro')
