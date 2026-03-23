from django.urls import path

from . import views

urlpatterns = [
	path('', views.wallet_snapshot, name='wallet-snapshot'),
	path('grant/', views.wallet_grant, name='wallet-grant'),
	path('buy/', views.wallet_buy, name='wallet-buy'),
	path('purchases/<int:purchase_id>/approve/', views.wallet_approve_purchase, name='wallet-approve-purchase'),
	path('purchases/<int:purchase_id>/reject/', views.wallet_reject_purchase, name='wallet-reject-purchase'),
	path('packs/', views.wallet_packs, name='wallet-packs'),
]
