from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Message

User = get_user_model()


class MessageTests(APITestCase):
	def setUp(self):
		self.sender = User.objects.create_user(username='alice', password='pass1234')
		self.receiver = User.objects.create_user(username='bob', password='pass1234')

	def test_send_message(self):
		url = reverse('message-list')
		payload = {'receiver': self.receiver.id, 'content': 'hello'}
		self.client.force_authenticate(user=self.sender)
		res = self.client.post(url, payload, format='json')
		self.assertEqual(res.status_code, status.HTTP_201_CREATED)
		self.assertEqual(Message.objects.count(), 1)
		msg = Message.objects.first()
		self.assertEqual(msg.sender, self.sender)
		self.assertEqual(msg.receiver, self.receiver)

	def test_mark_read(self):
		msg = Message.objects.create(sender=self.sender, receiver=self.receiver, content='hi')
		url = reverse('message-mark-read', args=[msg.id])
		self.client.force_authenticate(user=self.receiver)
		res = self.client.post(url)
		self.assertEqual(res.status_code, status.HTTP_200_OK)
		msg.refresh_from_db()
		self.assertTrue(msg.read_status)
