from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from feedback.models import Feedback


User = get_user_model()


class FeedbackApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='u1', password='pass1234')
        self.other = User.objects.create_user(username='u2', password='pass1234')

    def test_create_feedback_and_list_my(self):
        self.client.force_authenticate(user=self.user)
        create_resp = self.client.post(
            '/api/feedback/',
            {
                'type': 'problem',
                'message': 'App crashed on submit',
                'platform': 'android',
            },
            format='json',
        )
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)

        my_resp = self.client.get('/api/feedback/my/')
        self.assertEqual(my_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(my_resp.data), 1)
        self.assertEqual(my_resp.data[0]['type'], 'problem')

    def test_non_admin_cannot_update_feedback_status(self):
        item = Feedback.objects.create(
            user=self.user,
            type=Feedback.TYPE_PROBLEM,
            message='Hello',
        )
        self.client.force_authenticate(user=self.other)
        patch_resp = self.client.patch(
            f'/api/feedback/{item.id}/',
            {'status': Feedback.STATUS_RESOLVED},
            format='json',
        )
        self.assertEqual(patch_resp.status_code, status.HTTP_403_FORBIDDEN)
