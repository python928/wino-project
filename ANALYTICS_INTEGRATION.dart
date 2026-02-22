// =============================================================================
// INTEGRATION GUIDE — analytics system
// =============================================================================
// هذا الملف يوضح بالضبط كيف تربط نظام Analytics بالكود الحالي.
// اتبع كل خطوة حسب ترتيبها.
// =============================================================================

/*
─────────────────────────────────────────────────────────
STEP 1 — Backend: تشغيل migrations
─────────────────────────────────────────────────────────
cd app-backend
python manage.py makemigrations analytics
python manage.py migrate

─────────────────────────────────────────────────────────
STEP 2 — Backend: catalog/views.py
─────────────────────────────────────────────────────────
أضف هذا في أعلى الملف:
    from analytics.utils import log_user_event

ثم في ProductViewSet.retrieve() أو get_object():
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user.is_authenticated:
            log_user_event(request.user, 'view', product=instance)
        return super().retrieve(request, *args, **kwargs)

وفي list() إذا كان هناك search param:
    def list(self, request, *args, **kwargs):
        keyword = request.query_params.get('search', '').strip()
        if keyword and request.user.is_authenticated:
            log_user_event(request.user, 'search', metadata={'keyword': keyword})
        return super().list(request, *args, **kwargs)

─────────────────────────────────────────────────────────
STEP 3 — Flutter: Home screen
─────────────────────────────────────────────────────────
أضف هذا الـ import في ملف Home screen:
    import 'package:the_app/features/analytics/widgets/recommendations_list.dart';

ثم أضف هذا Widget في بداية الـ body (قبل قائمة المنتجات):
    RecommendationsList(),

─────────────────────────────────────────────────────────
STEP 4 — Flutter: صفحة تفاصيل المنتج
─────────────────────────────────────────────────────────
أضف هذا الـ import:
    import 'package:the_app/features/analytics/widgets/view_tracker.dart';

ثم لفّ الـ Scaffold الخاص بصفحة المنتج:
    return ViewTracker(
      productId: post.id,    // أو product.id حسب اسم المتغير عندك
      child: Scaffold(
        // ... الكود الحالي بدون تغيير
      ),
    );

─────────────────────────────────────────────────────────
STEP 5 — Flutter: شاشة البحث
─────────────────────────────────────────────────────────
أضف هذا الـ import:
    import 'package:the_app/features/analytics/widgets/search_tracker.dart';

ثم عند تنفيذ البحث (عادةً عند الضغط على زر البحث أو onSubmitted):
    SearchTracker.trackSearch(context, keyword: searchController.text);

─────────────────────────────────────────────────────────
STEP 6 — Backend: تحديث الـ Profiles دوريًا
─────────────────────────────────────────────────────────
شغّل هذا الأمر يدوياً للتجربة:
    python manage.py update_profiles

أو أضفه في cron job:
    0 * * * * cd /path/to/app-backend && python manage.py update_profiles
─────────────────────────────────────────────────────────
*/
