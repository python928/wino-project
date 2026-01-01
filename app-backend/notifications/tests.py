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
			sender=self.sender,
			receiver=self.receiver,
			type='message',
			content='hi',
		)
		url = reverse('notification-mark-read', args=[note.id])
		self.client.force_authenticate(user=self.receiver)
		res = self.client.post(url)
		self.assertEqual(res.status_code, status.HTTP_200_OK)
		note.refresh_from_db()
		self.assertTrue(note.is_read)
