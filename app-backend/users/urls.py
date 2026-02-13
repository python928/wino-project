from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import RegisterView, UserViewSet, MeView, ChangePasswordView, LogoutView, UserListView, UserDetailView, FollowerListView, FollowerToggleView

router = DefaultRouter()
router.register('users', UserViewSet, basename='user')

urlpatterns = [
    path('', include(router.urls)),
    path('register/', RegisterView.as_view(), name='register'),
    path('me/', MeView.as_view(), name='me'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),  
    path('followers/', FollowerListView.as_view(), name='followers'),
    path('followers/toggle/', FollowerToggleView.as_view(), name='follower-toggle'),
]
