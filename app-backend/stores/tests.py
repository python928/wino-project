from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse


User = get_user_model()


class StoreTests(APITestCase):
	def setUp(self):
		self.owner = User.objects.create_user(username='owner', password='pass1234')

	def test_create_store(self):
		url = reverse('store-list')
		payload = {
			'name': 'My Store',
			'description': 'Desc',
			'type': 'physical',
		}
		self.client.force_authenticate(user=self.owner)
		res = self.client.post(url, payload, format='json')
		self.assertEqual(res.status_code, status.HTTP_201_CREATED)
		self.assertEqual(res.data['name'], 'My Store')
