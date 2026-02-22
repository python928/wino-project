"""
================================================================================
ANALYTICS_INTEGRATION_CHECKLIST.md (as Python comment for easy reading)
================================================================================

✅ تم إنشاؤه:
  analytics/
    __init__.py
    apps.py              → ready() يربط signals تلقائياً
    models.py            → InteractionLog + UserInterestProfile
    admin.py             → تسجيل في Django Admin
    utils.py             → log_user_event, time_decay, price_range
    scoring.py           → update_user_profile, update_all_profiles
    recommendations.py   → get_recommended_products, get_similar_products
    serializers.py       → AnalyticsLogSerializer, RecommendationItemSerializer
    views.py             → RecommendationsAPIView, LogEventAPIView
    urls.py              → /api/analytics/recommendations/ + /api/analytics/log/
    signals.py           → Favorite + Review auto-tracking
    management/commands/
      update_profiles.py → python manage.py update_profiles
      seed_analytics.py  → python manage.py seed_analytics

✅ Backend integration:
  backend/urls.py        → path('api/analytics/', include('analytics.urls'))
  catalog/views.py       → retrieve() logs 'view', list() logs 'search'

✅ Flutter:
  core/services/analytics_api_service.dart
  features/analytics/
    analytics_export.dart          (barrel export)
    models/recommendation_item.dart
    providers/analytics_provider.dart
    widgets/recommendations_list.dart
    widgets/view_tracker.dart
    widgets/search_tracker.dart
  main.dart              → AnalyticsProvider في MultiProvider

⏳ يتطلب منك:
  1. python manage.py makemigrations analytics
  2. python manage.py migrate
  3. python manage.py seed_analytics   (للـ demo)
  4. إضافة RecommendationsList() في شاشة Home
  5. تغليف صفحة المنتج بـ ViewTracker(productId: ..., child: Scaffold(...))
  6. استدعاء SearchTracker.trackSearch(context, keyword: q) في شاشة البحث

================================================================================
"""
