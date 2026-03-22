from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import serializers, status
from rest_framework.test import APITestCase

from .models import CoinPurchase
from .services import ensure_can_create_post, get_coin_costs

User = get_user_model()


class WalletCoinRulesTests(APITestCase):
	def setUp(self):
		self.user = User.objects.create_user(username='wallet-merchant', password='pass1234')

	def test_post_coin_deduction_and_insufficient_payload(self):
		cost = int(get_coin_costs()['product'])
		self.user.coins_balance = cost
		self.user.save(update_fields=['coins_balance'])

		ensure_can_create_post(self.user, 'product')
		self.user.refresh_from_db()
		self.assertEqual(self.user.coins_balance, 0)

		with self.assertRaises(serializers.ValidationError) as exc:
			ensure_can_create_post(self.user, 'product')

		detail = exc.exception.detail
		self.assertEqual(detail.get('code'), 'INSUFFICIENT_COINS')
		self.assertIn('required', detail)
		self.assertIn('balance', detail)


class WalletPurchaseApprovalTests(APITestCase):
	def setUp(self):
		self.user = User.objects.create_user(username='buyer', password='pass1234')
		self.admin = User.objects.create_superuser(username='admin-wallet', password='pass1234')

	def test_buy_creates_pending_request_without_credit(self):
		self.client.force_authenticate(user=self.user)
		proof = SimpleUploadedFile(
			'proof.png',
			b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0bIDATx\x9cc```\x00\x00\x00\x04\x00\x01\x0b\xe7\x02\x9d\x00\x00\x00\x00IEND\xaeB`\x82',
			content_type='image/png',
		)
		res = self.client.post(
			reverse('wallet-buy'),
			{
				'pack_id': 'post_100',
				'payment_note': 'bank transfer',
				'images': [proof],
			},
			format='multipart',
		)
		self.assertEqual(res.status_code, status.HTTP_201_CREATED)
		purchase = CoinPurchase.objects.get(id=res.data['purchase']['id'])
		self.assertEqual(purchase.status, CoinPurchase.STATUS_PENDING)
		self.user.refresh_from_db()
		self.assertEqual(self.user.coins_balance, 0)

	def test_admin_approve_grants_coins_once(self):
		purchase = CoinPurchase.objects.create(
			user=self.user,
			pack_id='post_100',
			coins_amount=50,
			price_amount='500.00',
			status=CoinPurchase.STATUS_PENDING,
		)

		self.client.force_authenticate(user=self.admin)
		approve_url = reverse('wallet-approve-purchase', kwargs={'purchase_id': purchase.id})
		res1 = self.client.post(approve_url, {}, format='json')
		self.assertEqual(res1.status_code, status.HTTP_200_OK)
		self.assertTrue(res1.data['credited'])
		self.user.refresh_from_db()
		self.assertEqual(self.user.coins_balance, 50)

		res2 = self.client.post(approve_url, {}, format='json')
		self.assertEqual(res2.status_code, status.HTTP_200_OK)
		self.assertFalse(res2.data['credited'])
		self.user.refresh_from_db()
		self.assertEqual(self.user.coins_balance, 50)
