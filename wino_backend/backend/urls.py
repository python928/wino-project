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
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView
from users.views import CustomTokenObtainPairView


GOOGLE_DRIVE_FILE_ID = '1xPKPUBkh3yX_Zjdovny0XeTMhVGEoEja'
GOOGLE_DRIVE_VIEW_URL = f'https://drive.google.com/file/d/{GOOGLE_DRIVE_FILE_ID}/view'
GOOGLE_DRIVE_DOWNLOAD_URL = (
    f'https://drive.google.com/uc?export=download&id={GOOGLE_DRIVE_FILE_ID}'
)
YOUTUBE_TEMPLATE_URL = 'https://www.youtube.com/watch?v=7GyIot2Tg10&list=LL&index=1&t=16s'
YOUTUBE_EMBED_URL = 'https://www.youtube.com/embed/7GyIot2Tg10?start=16'
PAGE_BACKGROUND_URL = (
    'https://images.unsplash.com/photo-1526498460520-4c246339dccb?auto=format&fit=crop&w=1920&q=80'
)


class AppSchemeRedirect(HttpResponseRedirect):
    allowed_schemes = ['http', 'https', 'ftp', 'wino', 'toprice', 'intent']


def store_short_link_redirect(request, store_id):
    return AppSchemeRedirect(f'wino://store/{store_id}')


def product_short_link_redirect(request, product_id):
    return AppSchemeRedirect(f'wino://product/{product_id}')


def host_index(request):
    return render(
        request,
        'download/index.html',
        {
            'google_drive_download_url': GOOGLE_DRIVE_DOWNLOAD_URL,
            'youtube_embed_url': YOUTUBE_EMBED_URL,
            'page_background_url': PAGE_BACKGROUND_URL,
        },
    )


def download_app_index(request):
    return HttpResponseRedirect(GOOGLE_DRIVE_DOWNLOAD_URL)

urlpatterns = [
    path('', host_index, name='host_index'),
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
