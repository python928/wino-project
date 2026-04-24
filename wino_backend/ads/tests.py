from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from django.urls import reverse

from analytics.models import UserInterestProfile
from catalog.models import Category, Product

from .models import AdCampaign

User = get_user_model()


class HomeTopAdSelectionTests(APITestCase):
	def setUp(self):
		self.viewer = User.objects.create_user(
			username='viewer',
			password='pass1234',
			name='Viewer',
			address='Algiers',
		)
		self.store = User.objects.create_user(
			username='merchant',
			password='pass1234',
			name='Merchant',
			address='Algiers',
			latitude=36.7538,
			longitude=3.0588,
		)
		self.pref_category = Category.objects.create(name='Flowers')
		self.other_category = Category.objects.create(name='Electronics')
		self.product_a = Product.objects.create(
			store=self.store,
			category=self.pref_category,
			name='Preferred Product A',
			price='100.00',
		)
		self.product_b = Product.objects.create(
			store=self.store,
			category=self.pref_category,
			name='Preferred Product B',
			price='120.00',
		)
		self.product_c = Product.objects.create(
			store=self.store,
			category=self.other_category,
			name='Other Product',
			price='200.00',
		)
		self.ad_a = AdCampaign.objects.create(
			store=self.store,
			product=self.product_a,
			name='Ad A',
			placement=AdCampaign.PLACEMENT_HOME_TOP,
			target_categories=[str(self.pref_category.id)],
			is_active=True,
		)
		self.ad_b = AdCampaign.objects.create(
			store=self.store,
			product=self.product_b,
			name='Ad B',
			placement=AdCampaign.PLACEMENT_HOME_TOP,
			target_categories=[str(self.pref_category.id)],
			is_active=True,
		)
		self.ad_c = AdCampaign.objects.create(
			store=self.store,
			product=self.product_c,
			name='Ad C',
			placement=AdCampaign.PLACEMENT_HOME_TOP,
			target_categories=[str(self.other_category.id)],
			is_active=True,
		)
		UserInterestProfile.objects.create(
			user=self.viewer,
			category_scores={str(self.pref_category.id): 120.0},
			preferred_wilayas=['Algiers'],
		)

	def test_home_top_single_random_returns_one_preference_eligible_campaign(self):
		self.client.force_authenticate(user=self.viewer)
		url = (
			f"{reverse('ad-campaign-list')}"
			f"?placement=home_top&single_random=true"
		)

		response = self.client.get(url, format='json')

		self.assertEqual(response.status_code, status.HTTP_200_OK)
		items = response.data['results'] if isinstance(response.data, dict) else response.data
		self.assertEqual(len(items), 1)
		self.assertIn(items[0]['id'], {self.ad_a.id, self.ad_b.id})

		self.ad_a.refresh_from_db()
		self.ad_b.refresh_from_db()
		self.ad_c.refresh_from_db()
		self.assertEqual(
			self.ad_a.impressions_count + self.ad_b.impressions_count + self.ad_c.impressions_count,
			1,
		)
		self.assertEqual(self.ad_c.impressions_count, 0)

	def test_home_top_without_single_random_keeps_multiple_eligible_campaigns(self):
		self.client.force_authenticate(user=self.viewer)
		url = f"{reverse('ad-campaign-list')}?placement=home_top"

		response = self.client.get(url, format='json')

		self.assertEqual(response.status_code, status.HTTP_200_OK)
		items = response.data['results'] if isinstance(response.data, dict) else response.data
		ids = {item['id'] for item in items}
		self.assertTrue({self.ad_a.id, self.ad_b.id}.issubset(ids))
		self.assertNotIn(self.ad_c.id, ids)
