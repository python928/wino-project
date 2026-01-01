from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse


class RegisterTests(APITestCase):
	def test_register_returns_tokens(self):
		payload = {
			'username': 'alice',
			'email': 'alice@example.com',
			'password': 'Testpass123',
			'phone': '+123456',
		}
		url = reverse('register')
		response = self.client.post(url, payload, format='json')
		self.assertEqual(response.status_code, status.HTTP_201_CREATED)
		self.assertIn('access', response.data)
		self.assertIn('refresh', response.data)
