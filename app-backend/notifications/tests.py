from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Notification

User = get_user_model()


class NotificationTests(APITestCase):
	def setUp(self):
		self.sender = User.objects.create_user(username='alice', password='pass1234')
		self.receiver = User.objects.create_user(username='bob', password='pass1234')

	def test_mark_notification_read(self):
		note = Notification.objects.create(
			actor=self.sender,
			notification_type='system',
			title='hi',
			body='hello bob',
		)
		from .models import NotificationRecipient
		recipient = NotificationRecipient.objects.create(
			notification=note,
			user=self.receiver,
			is_read=False
		)
		url = reverse('notification-mark-read', args=[note.id])
		self.client.force_authenticate(user=self.receiver)
		res = self.client.post(url)
		self.assertEqual(res.status_code, status.HTTP_200_OK)
		recipient.refresh_from_db()
		self.assertTrue(recipient.is_read)
