from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse

from .models import Category, Product, Review

User = get_user_model()


class ProductTests(APITestCase):
	def setUp(self):
		self.owner = User.objects.create_user(username='owner', password='pass1234', name='Owner')
		self.category = Category.objects.create(name='Cat')

	def test_create_product(self):
		url = reverse('product-list')
		payload = {
			# store is read-only; viewset sets store=request.user
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


class ReviewTests(APITestCase):
	def setUp(self):
		self.store = User.objects.create_user(username='store', password='pass1234', name='Store')
		self.reviewer = User.objects.create_user(username='reviewer', password='pass1234', name='Reviewer')
		self.category = Category.objects.create(name='Food')
		self.product_1 = Product.objects.create(
			store=self.store,
			category=self.category,
			name='Product 1',
			price='10.00',
		)
		self.product_2 = Product.objects.create(
			store=self.store,
			category=self.category,
			name='Product 2',
			price='20.00',
		)

	def test_product_review_is_linked_to_specific_product(self):
		url = reverse('review-list')
		self.client.force_authenticate(user=self.reviewer)

		first = self.client.post(
			url,
			{'product': self.product_1.id, 'rating': 4, 'comment': 'good'},
			format='json',
		)
		self.assertEqual(first.status_code, status.HTTP_201_CREATED)
		self.assertEqual(Review.objects.count(), 1)
		self.assertEqual(Review.objects.first().product_id, self.product_1.id)

		# Same user + same product should update existing review.
		second = self.client.post(
			url,
			{'product': self.product_1.id, 'rating': 5, 'comment': 'better'},
			format='json',
		)
		self.assertEqual(second.status_code, status.HTTP_201_CREATED)
		self.assertEqual(Review.objects.count(), 1)
		self.assertEqual(Review.objects.first().rating, 5)

		# Same user + different product should create a second review.
		third = self.client.post(
			url,
			{'product': self.product_2.id, 'rating': 3, 'comment': 'ok'},
			format='json',
		)
		self.assertEqual(third.status_code, status.HTTP_201_CREATED)
		self.assertEqual(Review.objects.count(), 2)

	def test_product_reviews_list_filters_by_product_only(self):
		Review.objects.create(
			user=self.reviewer,
			store=self.store,
			product=self.product_1,
			rating=4,
			comment='p1',
		)
		Review.objects.create(
			user=self.store,
			store=self.store,
			product=None,
			rating=5,
			comment='store-level',
		)

		url = f"{reverse('review-list')}?product={self.product_1.id}"
		res = self.client.get(url, format='json')
		self.assertEqual(res.status_code, status.HTTP_200_OK)
		items = res.data['results'] if isinstance(res.data, dict) else res.data
		self.assertEqual(len(items), 1)
		self.assertEqual(items[0]['product'], self.product_1.id)
