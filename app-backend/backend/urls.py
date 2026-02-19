"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.contrib.auth.views import LogoutView
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView
from users.views import CustomTokenObtainPairView

urlpatterns = [
    # Override logout to allow GET redirect instead of 405 when hit directly
    path('admin/logout/',
         type(
             'LogoutAllowGet',
             (LogoutView,),
             {
                 'http_method_names': ['get', 'post', 'options'],
                 'get': lambda self, request, *args, **kwargs: self.post(request, *args, **kwargs),
             },
         ).as_view(next_page='/admin/login/'),
         name='admin_logout'),
    path('admin/', admin.site.urls),
    path('api/auth/token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # Unified profile system - all users are store owners by default
    path('api/users/', include('users.urls')),
    path('api/catalog/', include('catalog.urls')),
    # Remove unused messaging and notifications if not needed
    # path('api/messaging/', include('messaging.urls')),
    # path('api/notifications/', include('notifications.urls')),
    path('api/subscriptions/', include('subscriptions.urls')),
    path('api/analytics/', include('analytics.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
