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
from django.http import HttpResponse, HttpResponseRedirect
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView
from users.views import CustomTokenObtainPairView


class AppSchemeRedirect(HttpResponseRedirect):
    allowed_schemes = ['http', 'https', 'ftp', 'wino', 'toprice', 'intent']


def store_short_link_redirect(request, store_id):
    return AppSchemeRedirect(f'wino://store/{store_id}')


def product_short_link_redirect(request, product_id):
    return AppSchemeRedirect(f'wino://product/{product_id}')


def download_app_index(request):
    apk_url = 'https://wino.pythonanywhere.com/media/downloads/wino-app-release.apk'
    html = f'''<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Wino Android App Download</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 2rem; line-height: 1.5; }}
        .card {{ max-width: 680px; border: 1px solid #ddd; border-radius: 12px; padding: 1.2rem; }}
        .btn {{ display: inline-block; margin-top: 0.8rem; background: #0d6efd; color: #fff; text-decoration: none; padding: 0.7rem 1rem; border-radius: 8px; }}
        code {{ background: #f5f5f5; padding: 0.1rem 0.3rem; border-radius: 4px; }}
    </style>
</head>
<body>
    <div class="card">
        <h1>Wino Android App</h1>
        <p>Download the latest APK:</p>
        <p><a class="btn" href="{apk_url}">Download APK</a></p>
        <p>Direct link: <code>{apk_url}</code></p>
    </div>
</body>
</html>'''
    return HttpResponse(html)

urlpatterns = [
    path('download/', download_app_index, name='download_app_index'),
    path('s/<int:store_id>/', store_short_link_redirect, name='short_store_redirect'),
    path('p/<int:product_id>/', product_short_link_redirect, name='short_product_redirect'),
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
    path('api/ads/', include('ads.urls')),
    # Remove unused messaging and notifications if not needed
    # path('api/messaging/', include('messaging.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/subscriptions/', include('subscriptions.urls')),
    path('api/wallet/', include('wallet.urls')),
    path('api/analytics/', include('analytics.urls')),
    path('api/feedback/', include('feedback.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
