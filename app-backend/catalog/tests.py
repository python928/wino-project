from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse

from stores.models import Store
from .models import Category

User = get_user_model()


class ProductTests(APITestCase):
	def setUp(self):
		self.owner = User.objects.create_user(username='owner', password='pass1234')
		self.store = Store.objects.create(owner=self.owner, name='Store')
		self.category = Category.objects.create(name='Cat')

	def test_create_product(self):
		url = reverse('product-list')
		payload = {
			'store': self.store.id,
			'category': self.category.id,
			'name': 'Prod',
			'price': '10.00',
			'negotiable': False,
			'available_status': 'available',
		}
		self.client.force_authenticate(user=self.owner)
		res = self.client.post(url, payload, format='json')
		self.assertEqual(res.status_code, status.HTTP_201_CREATED)
		self.assertEqual(res.data['name'], 'Prod')
