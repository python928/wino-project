# 🧠 Smart Recommendation System — Full Technical Implementation Plan

## ✅ 50 To‑Do (الميزة غير موجودة حاليا) — Backend أولاً

> المطلوب: إضافة نظام Analytics + Recommendation Engine للسيرفر (Django/DRF) ثم ربطه لاحقاً بالـ Flutter.
> ملاحظة مهمة حسب المشروع الحالي: المنتجات/الأقسام موجودة داخل `catalog` وليس `products`.

### 1) تأسيس App analytics (1–10)
1. إنشاء app: `app-backend/analytics/`.
2. إضافة `analytics` إلى `INSTALLED_APPS` (تم).
3. إنشاء `analytics/apps.py` وربط `ready()` لتحميل signals.
4. إنشاء `analytics/__init__.py`.
5. إنشاء `analytics/admin.py` لتسجيل الموديلات.
6. إنشاء `analytics/migrations/__init__.py`.
7. إضافة إعدادات اختيارية في settings: lookback days/half-life (ثوابت).
8. التأكد من imports وعدم وجود تعارض اسم `analytics`.
9. تجهيز logging logger خاص بالـ analytics.
10. تجهيز خطة migrations وتشغيلها لاحقاً.

### 2) Models + DB (11–18)
11. إنشاء `InteractionLog` وربطه بـ `settings.AUTH_USER_MODEL`.
12. ربط `InteractionLog.product` بـ `catalog.Product` (FK nullable).
13. ربط `InteractionLog.category` بـ `catalog.Category` (FK nullable).
14. إضافة `metadata` JSONField + `session_id` + `timestamp`.
15. إضافة `UserInterestProfile` OneToOne مع User.
16. إضافة JSONFields: `category_scores`, `price_affinity`, `preferred_wilayas`, `search_keywords`, `preferred_sellers`.
17. إضافة float fields: `distance_sensitivity`, `quality_sensitivity`, `preferred_max_distance_km`.
18. إضافة indexes/ordering المناسبة على `InteractionLog`.

### 3) Utilities (19–24)
19. إنشاء `analytics/utils.py`.
20. تعريف `INTERACTION_WEIGHTS` طبقاً للخطة.
21. تعريف `PRICE_RANGES`.
22. إضافة `get_price_range(price)`.
23. إضافة `calculate_time_decay(dt, half_life_days=14)`.
24. إضافة `log_user_event(user, action, product=None, metadata=None, session_id='')` مع try/except.

### 4) Scoring (25–33)
25. إنشاء `analytics/scoring.py`.
26. تنفيذ `update_user_profile(user)` مع lookback 30 days.
27. حساب `category_scores` (weight × decay).
28. حساب `price_affinity` من product + filter_price.
29. حساب `distance_sensitivity` من `filter_dist`.
30. تعلم `preferred_max_distance_km` من متوسط km.
31. حساب `quality_sensitivity` من `filter_rating`.
32. استخراج `preferred_wilayas` من `filter_wilaya`.
33. استخراج `search_keywords` + `preferred_sellers`.

### 5) Recommendations Engine (34–41)
34. إنشاء `analytics/recommendations.py`.
35. تعديل الاستيراد لاستخدام `catalog.models.Product` بدل `products.models.Product`.
36. Cold start: popular products آخر 7 أيام (أو newest).
37. تنفيذ scoring components (category/price/quality/recency/popularity/seller_trust/negotiable/promotion).
38. إزالة recently viewed (آخر 6 ساعات).
39. Diversify: حد أقصى per seller.
40. إضافة `get_similar_products(product, limit=10)`.
41. توحيد مخرجات recommendation: product + score + reasons.

### 6) API (DRF) (42–48)
42. إنشاء `analytics/serializers.py` لعرض recommendation item بشكل مناسب.
43. إنشاء `analytics/views.py` (ViewSet أو APIView) لـ recommendations.
44. إنشاء endpoint: `GET /api/analytics/recommendations/`.
45. إنشاء endpoint: `POST /api/analytics/log/` لتسجيل أحداث من Flutter.
46. إضافة permissions (Authenticated) مع دعم اختياري للـ anonymous (تسجيل ممنوع).
47. إنشاء `analytics/urls.py` واستخدام `DefaultRouter`.
48. إضافة include في `app-backend/backend/urls.py`: `path('api/analytics/', include('analytics.urls'))`.

### 7) Auto-tracking (Signals/Integration) (49–50)
49. إضافة `analytics/signals.py` وربط favorite/review من `catalog` (إن كانت موديلاتها مكتملة).
50. (إن كانت الموديلات غير جاهزة) إضافة logging داخل `catalog` viewsets للأحداث الأساسية (view/search/favorite/contact) كحل أولي.
/..
---

## Algerian Local Smart Marketplace

> A recommendation engine designed specifically for the Algerian market.
> Built with Django, powered by behavioral analysis and a custom weighted ranking algorithm.

---

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Current Database Analysis](#2-current-database-analysis)
- [3. Architecture Overview](#3-architecture-overview)
- [4. Phase 1: Critical Foundation (Week 1–2)](#4-phase-1-critical-foundation-week-12-)
  - [4.1 New Database Models](#41-new-database-models)
  - [4.2 Interaction Logging Utility](#42-interaction-logging-utility)
  - [4.3 Scoring Engine](#43-scoring-engine)
  - [4.4 Recommendation Service](#44-recommendation-service)
  - [4.5 Management Command](#45-management-command)
- [5. Phase 2: Differentiating Features (Week 3–4)](#5-phase-2-differentiating-features-week-34-)
  - [5.1 Smart Notification Engine](#51-smart-notification-engine)
  - [5.2 Adaptive Search System](#52-adaptive-search-system)
  - [5.3 Django Signals for Auto-Tracking](#53-django-signals-for-auto-tracking)
  - [5.4 App Configuration](#54-app-configuration)
- [6. Phase 3: Future Enhancements (Post-Acceptance)](#6-phase-3-future-enhancements-post-acceptance-)
- [7. Scoring Formula Breakdown](#7-scoring-formula-breakdown)
- [8. File Structure](#8-file-structure)
- [9. Implementation Timeline](#9-implementation-timeline)
- [10. Startup Pitch Strengths](#10-startup-pitch-strengths)
- [11. Demo Preparation Tips](#11-demo-preparation-tips)

---

## 1. Project Overview

This document provides the **complete technical specification** for building a Smart Recommendation Engine for an Algerian local marketplace. The platform acts as a digital bridge between buyers and sellers, with features tailored to how Algerians actually buy and sell:

- **See before you pay** — No blind online purchasing; the buyer always inspects the product in person.
- **Built-in negotiation** — Sellers can open their prices for bargaining, reflecting real Algerian market culture.
- **Adaptive search radius** — Searching for a phone? Show nearby sellers. Searching for a car? Expand to multiple wilayas.
- **Smart matching** — The app learns from user behavior and shows personalized product recommendations.

The system relies on **Implicit Feedback Analysis** (what the user does, not what they say) and a **Custom Weighted Ranking Algorithm** — not a generic ML library, but a purpose-built formula for the Algerian context.

---

## 2. Current Database Analysis

The existing Django models provide a solid foundation:

| Model | Purpose | Key Fields |
|-------|---------|------------|
| `Category` | Product categories with parent-child hierarchy | `name`, `parent` (self-referential FK) |
| `Product` | Core product listing | `store` (FK to User), `category`, `name`, `price`, `hide_price`, `negotiable`, `available_status` |
| `ProductImage` | Product photos | `product`, `image`, `is_main` |
| `Promotion` | Discounts and special offers | `store`, `product`, `percentage`, `is_active`, `start_date`, `end_date` |
| `PromotionImage` | Promotion visuals | `promotion`, `image`, `is_main` |
| `Pack` | Product bundles | `merchant`, `name`, `discount` |
| `PackProduct` | Products within a pack | `pack`, `product`, `quantity` |
| `PackImage` | Pack visuals | `pack`, `image`, `is_main` |
| `Review` | User reviews for stores and products | `user`, `store`, `product`, `rating`, `comment` |
| `Favorite` | User's saved/favorited products | `user`, `product` |

**What's missing:** Behavioral tracking, interest profiling, and a recommendation service — which is exactly what this plan delivers.

---

## 3. Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                   USER (Buyer)                       │
│      Browses - Searches - Filters - Contacts - Saves │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│            Interaction Logging Layer                  │
│              analytics/utils.py                      │
│          log_user_event() + signals.py               │
│                                                      │
│   view(1) → click(2) → search(3) → favorite(5)      │
│   contact(10) → negotiate(8) → compare(6)            │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│          InteractionLog (Database Table)              │
│   Stores every raw interaction with timestamp +      │
│   metadata (keywords, price filters, distances)      │
└─────────────────────┬────────────────────────────────┘
                      │  Every hour (Management Command)
                      ▼
┌──────────────────────────────────────────────────────┐
│               Scoring Engine                         │
│            analytics/scoring.py                      │
│                                                      │
│   Time Decay × Weight = Category Score               │
│   + Price Affinity + Distance Sensitivity            │
│   + Quality Sensitivity + Keywords + Sellers         │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│       UserInterestProfile (Computed Profile)         │
│   category_scores, price_affinity, sensitivities     │
│   preferred_wilayas, search_keywords, sellers        │
└──────────┬──────────────────────┬────────────────────┘
           │                      │
           ▼                      ▼
┌────────────────────┐  ┌─────────────────────────────┐
│ Recommendation     │  │  Smart Notification Engine   │
│ Engine             │  │  notifications.py            │
│                    │  │                             │
│ Score = Σ(Wi × Si) │  │  New product matches you!    │
│ Cat×0.30           │  │  Price drop on watched item! │
│ + Price×0.15       │  ���  Search result for "samsung" │
│ + Quality×0.15     │  │                             │
│ + Recency×0.10     │  │  → Personalized alerts       │
│ + Popularity×0.10  │  │                             │
│ + Trust×0.10       │  └─────────────────────────────┘
│ + Negotiable×0.05  │
│ + Promotion×0.05   │
│                    │
│ → Top 20 products  │
└────────────────────┘
```

---

## 4. Phase 1: Critical Foundation (Week 1–2) 🔴

> **This phase alone is enough for a Startup pitch demo.**

### 4.1 New Database Models

Create a new Django app called `analytics`.

```python
# analytics/models.py

from django.conf import settings
from django.db import models


class UserInterestProfile(models.Model):
    """
    Stores computed user preferences.
    Updated periodically from raw InteractionLog data.
    One-to-one relationship with the User model.
    """
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='interest_profile'
    )

    # Category interest scores: {"1": 85.5, "4": 42.0}
    # Key = category_id (as string), Value = interest score (0-100+)
    category_scores = models.JSONField(default=dict, blank=True)

    # Price range affinity: {"low": 30, "medium": 55, "high": 15}
    # Ranges: very_low (0-2000), low (2000-5000), medium (5000-30000),
    #         high (30000-100000), very_high (100000+) — all in DZD
    price_affinity = models.JSONField(default=dict, blank=True)

    # Distance sensitivity: starts at 1.0
    # Increases as user applies distance filters more frequently
    # Higher value = user prefers nearby results
    distance_sensitivity = models.FloatField(default=1.0)

    # Quality sensitivity: starts at 1.0
    # Increases as user filters by high ratings
    quality_sensitivity = models.FloatField(default=1.0)

    # Learned maximum acceptable distance in kilometers
    preferred_max_distance_km = models.FloatField(default=50.0)

    # Preferred wilayas (Algerian provinces): ["16", "09", "35"]
    preferred_wilayas = models.JSONField(default=list, blank=True)

    # Most searched keywords: {"samsung": 5, "iphone": 3}
    search_keywords = models.JSONField(default=dict, blank=True)

    # Auto-detected preferred sellers: [user_id_1, user_id_2]
    preferred_sellers = models.JSONField(default=list, blank=True)

    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Interest Profile"
        verbose_name_plural = "User Interest Profiles"

    def __str__(self):
        return f"Interest Profile: {self.user}"

    def get_top_categories(self, limit=5):
        """Returns the top N category IDs by interest score."""
        if not self.category_scores:
            return []
        sorted_cats = sorted(
            self.category_scores.items(),
            key=lambda x: x[1],
            reverse=True
        )
        return [int(cat_id) for cat_id, _ in sorted_cats[:limit]]

    def get_price_range_preference(self):
        """Returns the most preferred price range name."""
        if not self.price_affinity:
            return 'medium'
        return max(self.price_affinity, key=self.price_affinity.get)


class InteractionLog(models.Model):
    """
    Records every raw user interaction for later processing.
    This is the raw data source — never modified, only appended.
    """
    ACTION_CHOICES = (
        ('view', 'View Product'),             # Weight: 1
        ('click', 'Click Product'),           # Weight: 2
        ('search', 'Search Keyword'),         # Weight: 3
        ('filter_price', 'Filter by Price'),  # Weight: 3
        ('filter_dist', 'Filter by Distance'),# Weight: 3
        ('filter_wilaya', 'Filter by Wilaya'),# Weight: 3
        ('filter_rating', 'Filter by Rating'),# Weight: 3
        ('contact', 'Contact Seller'),        # Weight: 10
        ('favorite', 'Add to Favorites'),     # Weight: 5
        ('negotiate', 'Request Negotiation'), # Weight: 8
        ('share', 'Share Product'),           # Weight: 4
        ('compare', 'Compare Product'),       # Weight: 6
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='interactions'
    )
    product = models.ForeignKey(
        'products.Product',
        null=True, blank=True,
        on_delete=models.SET_NULL,
        related_name='interactions'
    )
    category = models.ForeignKey(
        'products.Category',
        null=True, blank=True,
        on_delete=models.SET_NULL
    )
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)

    # Contextual metadata varies by action type:
    # search:       {"keyword": "samsung galaxy", "results_count": 15}
    # filter_price: {"min": 5000, "max": 20000}
    # filter_dist:  {"km": 25}
    # filter_wilaya:{"wilaya_code": "16", "wilaya_name": "Algiers"}
    # view:         {"duration_seconds": 45}
    metadata = models.JSONField(default=dict, blank=True)

    # Session grouping — to correlate related interactions
    session_id = models.CharField(max_length=100, blank=True, default='')

    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user', 'action', 'timestamp']),
            models.Index(fields=['user', 'category']),
            models.Index(fields=['timestamp']),
        ]
        verbose_name = "Interaction Log"
        verbose_name_plural = "Interaction Logs"

    def __str__(self):
        return f"{self.user} - {self.action} - {self.timestamp}"
```

---

### 4.2 Interaction Logging Utility

```python
# analytics/utils.py

import logging
import math

from django.utils import timezone

logger = logging.getLogger(__name__)


# ============================================
# Interaction Weights — The Heart of the System
# ============================================
INTERACTION_WEIGHTS = {
    'view': 1,
    'click': 2,
    'search': 3,
    'filter_price': 3,
    'filter_dist': 3,
    'filter_wilaya': 3,
    'filter_rating': 3,
    'share': 4,
    'favorite': 5,
    'compare': 6,
    'negotiate': 8,
    'contact': 10,
}

# Price ranges in Algerian Dinar (DZD)
PRICE_RANGES = {
    'very_low': (0, 2000),
    'low': (2000, 5000),
    'medium': (5000, 30000),
    'high': (30000, 100000),
    'very_high': (100000, float('inf')),
}


def log_user_event(user, action, product=None, metadata=None):
    """
    Log a user interaction event. Call this from anywhere in the codebase.

    Usage examples:
        log_user_event(request.user, 'view', product=product_obj)
        log_user_event(request.user, 'search', metadata={'keyword': 'samsung phone'})
        log_user_event(request.user, 'filter_price', metadata={'min': 5000, 'max': 20000})
        log_user_event(request.user, 'contact', product=product_obj)
        log_user_event(request.user, 'negotiate', product=product_obj)

    Args:
        user: The current user instance.
        action: Event type string (must match ACTION_CHOICES).
        product: (Optional) The Product object involved.
        metadata: (Optional) Dictionary with extra contextual data.

    Returns:
        InteractionLog instance or None if logging failed.
    """
    if metadata is None:
        metadata = {}

    # Skip anonymous users
    if not user or not user.is_authenticated:
        return None

    try:
        from analytics.models import InteractionLog

        category = None
        if product and product.category:
            category = product.category

        log_entry = InteractionLog.objects.create(
            user=user,
            product=product,
            category=category,
            action=action,
            metadata=metadata,
        )

        return log_entry

    except Exception as e:
        # Never let a logging error break the main application flow
        logger.error(f"Failed to log user event: {e}")
        return None


def get_price_range(price):
    """
    Determine which price range a given price falls into.

    Args:
        price: Numeric price value in DZD.

    Returns:
        String range name: 'very_low', 'low', 'medium', 'high', or 'very_high'.
    """
    price = float(price)
    for range_name, (low, high) in PRICE_RANGES.items():
        if low <= price < high:
            return range_name
    return 'very_high'


def calculate_time_decay(interaction_date, half_life_days=14):
    """
    Calculate a time decay factor for an interaction.
    Recent interactions have higher value; older ones fade.

    Uses exponential decay with a configurable half-life.
    After `half_life_days` days, the value drops to 50%.

    Args:
        interaction_date: DateTime of the interaction.
        half_life_days: Number of days for value to halve (default: 14).

    Returns:
        Float between 0.01 and 1.0.
    """
    now = timezone.now()
    age_days = (now - interaction_date).days
    decay = math.pow(0.5, age_days / half_life_days)
    return max(decay, 0.01)  # Floor at 1% — never fully zero
```

---

### 4.3 Scoring Engine

This converts raw `InteractionLog` data into numerical scores stored in `UserInterestProfile`.

```python
# analytics/scoring.py

"""
Scoring Engine
Transforms raw interaction logs into computed interest scores.
Run periodically via Management Command (or Celery in production).
"""

import logging
from collections import defaultdict
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Count
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.utils import (
    INTERACTION_WEIGHTS,
    calculate_time_decay,
    get_price_range,
)

logger = logging.getLogger(__name__)
User = get_user_model()


def update_user_profile(user):
    """
    Update a single user's interest profile based on the last 30 days
    of interactions.

    Algorithm steps:
    1. Calculate category scores (weighted + time-decayed)
    2. Calculate price range affinity
    3. Calculate distance sensitivity
    4. Calculate quality sensitivity
    5. Extract preferred wilayas
    6. Extract top search keywords
    7. Identify preferred sellers

    Args:
        user: User instance to update.

    Returns:
        Updated UserInterestProfile instance.
    """
    profile, created = UserInterestProfile.objects.get_or_create(user=user)

    # Fetch interactions from the last 30 days
    thirty_days_ago = timezone.now() - timedelta(days=30)
    interactions = InteractionLog.objects.filter(
        user=user,
        timestamp__gte=thirty_days_ago
    ).select_related('product', 'category', 'product__category')

    if not interactions.exists():
        return profile

    # ---- Step 1: Category Scores ----
    category_scores = defaultdict(float)
    for interaction in interactions:
        cat_id = None
        if interaction.category_id:
            cat_id = str(interaction.category_id)
        elif interaction.product and interaction.product.category_id:
            cat_id = str(interaction.product.category_id)

        if cat_id:
            weight = INTERACTION_WEIGHTS.get(interaction.action, 1)
            decay = calculate_time_decay(interaction.timestamp)
            category_scores[cat_id] += weight * decay

    profile.category_scores = dict(category_scores)

    # ---- Step 2: Price Affinity ----
    price_affinity = defaultdict(float)
    price_relevant_actions = ['view', 'click', 'contact', 'favorite', 'negotiate', 'compare']

    for interaction in interactions:
        # From product interactions
        if interaction.action in price_relevant_actions and interaction.product:
            price = interaction.product.price
            if price and price > 0:
                range_name = get_price_range(price)
                weight = INTERACTION_WEIGHTS.get(interaction.action, 1)
                decay = calculate_time_decay(interaction.timestamp)
                price_affinity[range_name] += weight * decay

        # From explicit price filter usage
        if interaction.action == 'filter_price':
            meta = interaction.metadata or {}
            if 'min' in meta and 'max' in meta:
                avg_price = (float(meta['min']) + float(meta['max'])) / 2
                range_name = get_price_range(avg_price)
                price_affinity[range_name] += 3 * calculate_time_decay(interaction.timestamp)

    profile.price_affinity = dict(price_affinity)

    # ---- Step 3: Distance Sensitivity ----
    dist_filter_count = interactions.filter(action='filter_dist').count()
    profile.distance_sensitivity = 1.0 + (dist_filter_count * 0.1)

    # Learn preferred maximum distance
    dist_interactions = interactions.filter(action='filter_dist')
    if dist_interactions.exists():
        distances = []
        for inter in dist_interactions:
            km = (inter.metadata or {}).get('km')
            if km:
                distances.append(float(km))
        if distances:
            profile.preferred_max_distance_km = sum(distances) / len(distances)

    # ---- Step 4: Quality Sensitivity ----
    rating_filter_count = interactions.filter(action='filter_rating').count()
    profile.quality_sensitivity = 1.0 + (rating_filter_count * 0.15)

    # ---- Step 5: Preferred Wilayas ----
    wilaya_interactions = interactions.filter(action='filter_wilaya')
    wilaya_counts = defaultdict(int)
    for inter in wilaya_interactions:
        code = (inter.metadata or {}).get('wilaya_code')
        if code:
            wilaya_counts[code] += 1
    if wilaya_counts:
        sorted_wilayas = sorted(wilaya_counts.items(), key=lambda x: x[1], reverse=True)
        profile.preferred_wilayas = [w[0] for w in sorted_wilayas[:10]]

    # ---- Step 6: Search Keywords ----
    search_interactions = interactions.filter(action='search')
    keywords = defaultdict(int)
    for inter in search_interactions:
        kw = (inter.metadata or {}).get('keyword', '').strip().lower()
        if kw:
            keywords[kw] += 1
    if keywords:
        sorted_kw = sorted(keywords.items(), key=lambda x: x[1], reverse=True)
        profile.search_keywords = dict(sorted_kw[:20])  # Keep top 20

    # ---- Step 7: Preferred Sellers ----
    seller_scores = defaultdict(float)
    strong_actions = ['contact', 'negotiate', 'favorite']
    for interaction in interactions:
        if interaction.action in strong_actions and interaction.product:
            seller_id = interaction.product.store_id
            if seller_id:
                weight = INTERACTION_WEIGHTS.get(interaction.action, 1)
                seller_scores[seller_id] += weight

    if seller_scores:
        sorted_sellers = sorted(seller_scores.items(), key=lambda x: x[1], reverse=True)
        profile.preferred_sellers = [s[0] for s in sorted_sellers[:10]]

    profile.save()
    return profile


def update_all_profiles():
    """
    Update all user profiles that have recent interactions.
    Intended to run periodically (every hour via cron or Celery).

    Returns:
        Number of profiles updated.
    """
    thirty_days_ago = timezone.now() - timedelta(days=30)
    active_user_ids = InteractionLog.objects.filter(
        timestamp__gte=thirty_days_ago
    ).values_list('user_id', flat=True).distinct()

    updated = 0
    for user_id in active_user_ids:
        try:
            user = User.objects.get(id=user_id)
            update_user_profile(user)
            updated += 1
        except User.DoesNotExist:
            continue
        except Exception as e:
            logger.error(f"Error updating profile for user {user_id}: {e}")

    logger.info(f"Updated {updated} user profiles")
    return updated
```

---

### 4.4 Recommendation Service

This is the **core engine** — called in views to return personalized product suggestions.

```python
# analytics/recommendations.py

"""
Smart Recommendation Service
Custom-built algorithm for the Algerian marketplace.
"""

import logging
from collections import defaultdict

from django.db.models import Avg, Q
from django.utils import timezone

from analytics.models import InteractionLog, UserInterestProfile
from analytics.utils import get_price_range, INTERACTION_WEIGHTS

logger = logging.getLogger(__name__)


# ============================================
# Main Scoring Weights
# ============================================
SCORE_WEIGHTS = {
    'category': 0.30,       # Category match
    'price': 0.15,          # Price range match
    'quality': 0.15,        # Product/seller rating
    'recency': 0.10,        # How new the product listing is
    'popularity': 0.10,     # How popular the product is this week
    'seller_trust': 0.10,   # Seller reputation score
    'negotiable': 0.05,     # Is price negotiable (Algerian feature!)
    'promotion': 0.05,      # Active discount/promotion
}


def get_recommended_products(user, limit=20, category_filter=None, wilaya_filter=None):
    """
    Main recommendation engine entry point.

    Algorithm:
    1. Load or create the user's interest profile
    2. Identify candidate products from top preferred categories
    3. Score each candidate using the weighted formula
    4. Remove recently viewed products (last 6 hours)
    5. Diversify results (max 4 per seller)
    6. Return top N results with score breakdowns

    Args:
        user: Authenticated User instance.
        limit: Number of products to return (default: 20).
        category_filter: Optional category ID to restrict results.
        wilaya_filter: Optional wilaya code to restrict results.

    Returns:
        List of dicts, each containing:
        - 'product': Product instance
        - 'score': Final computed score (float)
        - 'breakdown': Dict of individual score components
        - 'match_reasons': List of human-readable match explanations
    """
    from products.models import Product

    # ---- Step 1: Load Interest Profile ----
    try:
        profile = UserInterestProfile.objects.get(user=user)
    except UserInterestProfile.DoesNotExist:
        # New user with no history → serve popular products (Cold Start)
        return _get_popular_products(limit)

    # ---- Step 2: Identify Candidate Categories ----
    top_categories = profile.get_top_categories(limit=7)

    if not top_categories:
        return _get_popular_products(limit)

    # ---- Step 3: Fetch Candidate Products ----
    candidates_query = Product.objects.filter(
        available_status=Product.AVAILABLE
    ).select_related(
        'store', 'category'
    ).prefetch_related(
        'reviews', 'images', 'promotions'
    )

    if category_filter:
        candidates_query = candidates_query.filter(category_id=category_filter)
    else:
        # Include top categories AND their subcategories
        candidates_query = candidates_query.filter(
            Q(category_id__in=top_categories) |
            Q(category__parent_id__in=top_categories)
        )

    # Cap at 150 candidates for in-memory scoring
    candidates = list(candidates_query[:150])

    if not candidates:
        return _get_popular_products(limit)

    # ---- Step 4: Score Each Candidate ----
    scored_products = []
    for product in candidates:
        score_breakdown = _calculate_product_score(product, profile)
        final_score = sum(
            score_breakdown[key] * SCORE_WEIGHTS[key]
            for key in SCORE_WEIGHTS
        )
        scored_products.append({
            'product': product,
            'score': round(final_score, 2),
            'breakdown': score_breakdown,
            'match_reasons': _get_match_reasons(score_breakdown),
        })

    # ---- Step 5: Remove Recently Viewed ----
    recently_viewed = set(
        InteractionLog.objects.filter(
            user=user,
            action='view',
            timestamp__gte=timezone.now() - timezone.timedelta(hours=6)
        ).values_list('product_id', flat=True)
    )

    scored_products = [
        sp for sp in scored_products
        if sp['product'].id not in recently_viewed
    ]

    # ---- Step 6: Sort and Diversify ----
    scored_products.sort(key=lambda x: x['score'], reverse=True)
    final_results = _diversify_results(scored_products, max_per_seller=4)

    return final_results[:limit]


def _calculate_product_score(product, profile):
    """
    Calculate individual score components for a single product.
    Each component returns a value between 0 and 100.
    """
    scores = {}

    # 1. Category Match Score (0–100)
    cat_id = str(product.category_id) if product.category_id else None
    if cat_id and cat_id in profile.category_scores:
        max_cat_score = max(profile.category_scores.values()) if profile.category_scores else 1
        scores['category'] = min(
            (profile.category_scores[cat_id] / max_cat_score) * 100, 100
        )
    else:
        scores['category'] = 0

    # 2. Price Match Score (0–100)
    if product.price and not product.hide_price:
        product_range = get_price_range(product.price)
        preferred_range = profile.get_price_range_preference()
        if product_range == preferred_range:
            scores['price'] = 100
        elif _ranges_adjacent(product_range, preferred_range):
            scores['price'] = 60
        else:
            scores['price'] = 20
    else:
        scores['price'] = 50  # Hidden price → neutral score

    # 3. Quality Score (0–100) — Uses Wilson Score-like confidence
    avg_rating = product.reviews.aggregate(avg=Avg('rating'))['avg']
    review_count = product.reviews.count()
    if avg_rating:
        confidence = min(review_count / 10, 1.0)  # Full confidence at 10 reviews
        scores['quality'] = (avg_rating / 5) * 100 * confidence * profile.quality_sensitivity
        scores['quality'] = min(scores['quality'], 100)
    else:
        scores['quality'] = 30  # No reviews → base score

    # 4. Recency Score (0–100)
    age_days = (timezone.now() - product.created_at).days
    if age_days <= 1:
        scores['recency'] = 100
    elif age_days <= 7:
        scores['recency'] = 80
    elif age_days <= 30:
        scores['recency'] = 50
    else:
        scores['recency'] = max(20, 50 - age_days)

    # 5. Popularity Score (0–100)
    interaction_count = InteractionLog.objects.filter(
        product=product,
        timestamp__gte=timezone.now() - timezone.timedelta(days=7)
    ).count()
    scores['popularity'] = min(interaction_count * 5, 100)

    # 6. Seller Trust Score (0–100)
    seller = product.store
    seller_avg_rating = seller.store_reviews.aggregate(avg=Avg('rating'))['avg']
    seller_review_count = seller.store_reviews.count()
    if seller_avg_rating:
        confidence = min(seller_review_count / 5, 1.0)
        scores['seller_trust'] = (seller_avg_rating / 5) * 100 * confidence
    else:
        scores['seller_trust'] = 40

    # Bonus if seller is in user's preferred sellers list
    if seller.id in (profile.preferred_sellers or []):
        scores['seller_trust'] = min(scores['seller_trust'] * 1.3, 100)

    # 7. Negotiable Score (0–100) — Unique Algerian feature!
    scores['negotiable'] = 100 if product.negotiable else 30

    # 8. Promotion Score (0–100)
    active_promotions = product.promotions.filter(
        is_active=True,
        start_date__lte=timezone.now(),
        end_date__gte=timezone.now()
    )
    if active_promotions.exists():
        best_discount = max(p.percentage for p in active_promotions)
        scores['promotion'] = min(float(best_discount) * 2, 100)
    else:
        scores['promotion'] = 0

    return scores


def _ranges_adjacent(range1, range2):
    """Check if two price ranges are adjacent."""
    order = ['very_low', 'low', 'medium', 'high', 'very_high']
    try:
        idx1 = order.index(range1)
        idx2 = order.index(range2)
        return abs(idx1 - idx2) <= 1
    except ValueError:
        return False


def _get_match_reasons(breakdown):
    """
    Generate human-readable match explanations for the UI.
    Shown to the user as tags like "Matches your interests", "Good price for you", etc.
    """
    reasons = []
    if breakdown.get('category', 0) >= 70:
        reasons.append('Matches your interests')
    if breakdown.get('price', 0) >= 80:
        reasons.append('Fits your budget')
    if breakdown.get('quality', 0) >= 70:
        reasons.append('Highly rated')
    if breakdown.get('negotiable', 0) >= 100:
        reasons.append('Price negotiable')
    if breakdown.get('promotion', 0) >= 50:
        reasons.append('On sale!')
    if breakdown.get('recency', 0) >= 80:
        reasons.append('Just listed')
    if breakdown.get('seller_trust', 0) >= 80:
        reasons.append('Trusted seller')
    return reasons


def _diversify_results(scored_products, max_per_seller=4):
    """
    Prevent a single seller from dominating the results.
    Ensures variety by capping products per seller.
    """
    seller_counts = defaultdict(int)
    diversified = []

    for sp in scored_products:
        seller_id = sp['product'].store_id
        if seller_counts[seller_id] < max_per_seller:
            diversified.append(sp)
            seller_counts[seller_id] += 1

    return diversified


def _get_popular_products(limit=20):
    """
    Cold Start Solution: For new users with no interaction history.
    Returns the most popular products from the last 7 days.
    Falls back to newest products if no interaction data exists.
    """
    from products.models import Product

    # Most interacted products this week
    popular_ids = InteractionLog.objects.filter(
        timestamp__gte=timezone.now() - timezone.timedelta(days=7),
        product__isnull=False
    ).values('product_id').annotate(
        count=models.Count('id')
    ).order_by('-count').values_list('product_id', flat=True)[:limit]

    if not popular_ids:
        # No interaction data at all → return newest products
        products = Product.objects.filter(
            available_status=Product.AVAILABLE
        ).order_by('-created_at')[:limit]
        return [
            {
                'product': p,
                'score': 0,
                'breakdown': {},
                'match_reasons': ['New listing'],
            }
            for p in products
        ]

    products = Product.objects.filter(
        id__in=popular_ids,
        available_status=Product.AVAILABLE
    ).select_related('store', 'category')

    return [
        {
            'product': p,
            'score': 50,
            'breakdown': {},
            'match_reasons': ['Trending this week'],
        }
        for p in products
    ]


def get_similar_products(product, limit=10):
    """
    "You might also like" — shown on product detail pages.
    Returns products in the same category with similar price range.

    Args:
        product: The current Product instance being viewed.
        limit: Number of similar products to return.

    Returns:
        QuerySet of similar Product instances.
    """
    from products.models import Product

    similar = Product.objects.filter(
        category=product.category,
        available_status=Product.AVAILABLE
    ).exclude(
        id=product.id
    ).select_related('store', 'category')

    # Filter by similar price range (±30%)
    if product.price:
        price_range = float(product.price) * 0.3
        similar = similar.filter(
            price__gte=float(product.price) - price_range,
            price__lte=float(product.price) + price_range
        )

    return similar.order_by('-created_at')[:limit]
```

---

### 4.5 Management Command

```python
# analytics/management/commands/update_profiles.py

"""
Management command to update all user interest profiles.

Usage:
    python manage.py update_profiles

Recommended: Run via cron job every hour.
    0 * * * * cd /path/to/project && python manage.py update_profiles
"""

from django.core.management.base import BaseCommand

from analytics.scoring import update_all_profiles


class Command(BaseCommand):
    help = 'Update interest profiles for all active users based on recent interactions.'

    def handle(self, *args, **options):
        self.stdout.write('Starting profile updates...')
        count = update_all_profiles()
        self.stdout.write(
            self.style.SUCCESS(f'Successfully updated {count} user profiles.')
        )
```

---

## 5. Phase 2: Differentiating Features (Week 3–4) 🟡

> **These features make your project stand out against competitors in front of the jury.**

### 5.1 Smart Notification Engine

```python
# analytics/notifications.py

"""
Smart Notification Engine
Sends personalized alerts only when there is a real match.
No spam — only relevant, targeted notifications.
"""

import logging

from django.utils import timezone

from analytics.models import UserInterestProfile
from analytics.utils import get_price_range

logger = logging.getLogger(__name__)


class SmartNotificationEngine:
    """
    Monitors new products, price drops, and keyword matches,
    then identifies which users should be notified.
    """

    # Minimum match score required to trigger a notification
    MIN_MATCH_SCORE = 60

    @staticmethod
    def check_new_product(product):
        """
        When a new product is added: who should be notified?

        Scans all user profiles that have interest in the product's category.
        Applies price matching as a bonus multiplier.

        Args:
            product: The newly created Product instance.

        Returns:
            List of notification dicts with 'user', 'product', 'match_score', 'reason'.
        """
        notifications = []
        cat_id = str(product.category_id) if product.category_id else None

        if not cat_id:
            return notifications

        # Find users interested in this category
        profiles = UserInterestProfile.objects.filter(
            category_scores__has_key=cat_id
        ).select_related('user')

        for profile in profiles:
            score = profile.category_scores.get(cat_id, 0)

            # Check for price match bonus
            price_match = False
            if product.price:
                product_range = get_price_range(product.price)
                preferred_range = profile.get_price_range_preference()
                price_match = product_range == preferred_range

            # Calculate overall match score
            match_score = score
            if price_match:
                match_score *= 1.3

            if match_score >= SmartNotificationEngine.MIN_MATCH_SCORE:
                notifications.append({
                    'user': profile.user,
                    'product': product,
                    'match_score': match_score,
                    'reason': _build_notification_message(product, price_match),
                })

        return notifications

    @staticmethod
    def check_price_drop(product, old_price, new_price):
        """
        When a product's price drops: notify users who showed interest.

        Targets users who favorited, contacted, negotiated, or viewed the product
        in the last 30 days.

        Args:
            product: The Product instance with reduced price.
            old_price: Previous price (Decimal/float).
            new_price: New lower price (Decimal/float).

        Returns:
            List of notification dicts.
        """
        from analytics.models import InteractionLog

        interested_users = InteractionLog.objects.filter(
            product=product,
            action__in=['favorite', 'contact', 'negotiate', 'view'],
            timestamp__gte=timezone.now() - timezone.timedelta(days=30)
        ).values_list('user_id', flat=True).distinct()

        discount_pct = ((float(old_price) - float(new_price)) / float(old_price)) * 100

        notifications = []
        for user_id in interested_users:
            notifications.append({
                'user_id': user_id,
                'product': product,
                'type': 'price_drop',
                'message': (
                    f'{discount_pct:.0f}% price drop on {product.name}! '
                    f'New price: {new_price} DZD (was {old_price} DZD)'
                ),
            })

        return notifications

    @staticmethod
    def check_keyword_match(product):
        """
        Check if a new product matches any user's past search keywords.

        Scans user profiles with stored keywords and checks if any appear
        in the new product's name or description.

        Args:
            product: The newly created Product instance.

        Returns:
            List of notification dicts.
        """
        product_text = f"{product.name} {product.description}".lower()

        profiles_with_keywords = UserInterestProfile.objects.exclude(
            search_keywords={}
        ).select_related('user')

        notifications = []
        for profile in profiles_with_keywords:
            for keyword, count in (profile.search_keywords or {}).items():
                if keyword.lower() in product_text and count >= 2:
                    notifications.append({
                        'user': profile.user,
                        'product': product,
                        'type': 'keyword_match',
                        'message': (
                            f'New product matching your search for '
                            f'"{keyword}": {product.name}'
                        ),
                    })
                    break  # One notification per user per product

        return notifications


def _build_notification_message(product, price_match):
    """Build a human-readable notification message."""
    msg = f'New product you might like: {product.name}'
    if price_match:
        msg += f' — Fits your budget ({product.price} DZD)'
    if product.negotiable:
        msg += ' — Price negotiable!'
    return msg
```

---

### 5.2 Adaptive Search System

```python
# analytics/adaptive_search.py

"""
Adaptive Search System
Automatically adjusts search radius based on product type.

This is a UNIQUE feature — no Algerian platform offers this.

Logic:
- Searching for a phone? → Show nearby sellers first (20-30 km)
- Searching for a car? → Expand to 500 km across multiple wilayas
- User can always override manually
"""

# Categories that require WIDE search (buyer is willing to travel)
WIDE_SEARCH_CATEGORIES = {
    'Cars': {'default_radius_km': 500, 'description': 'Cars and vehicles'},
    'Real Estate': {'default_radius_km': 300, 'description': 'Properties and land'},
    'Trucks': {'default_radius_km': 500, 'description': 'Trucks and heavy vehicles'},
    'Industrial Equipment': {'default_radius_km': 500, 'description': 'Industrial machinery'},
    'Land': {'default_radius_km': 400, 'description': 'Agricultural and construction land'},
    'Rare Parts': {'default_radius_km': 500, 'description': 'Rare and used spare parts'},
}

# Categories that require LOCAL search (buyer wants nearby)
LOCAL_SEARCH_CATEGORIES = {
    'Electronics': {'default_radius_km': 30},
    'Clothing': {'default_radius_km': 20},
    'Home Appliances': {'default_radius_km': 25},
    'Groceries': {'default_radius_km': 15},
    'Cosmetics': {'default_radius_km': 20},
    'Furniture': {'default_radius_km': 50},
}


def get_adaptive_search_radius(category_name, user_profile=None):
    """
    Determine the optimal search radius based on:
    1. Product category type (wide vs. local)
    2. User's learned distance preferences

    Args:
        category_name: Name of the product category.
        user_profile: (Optional) UserInterestProfile instance.

    Returns:
        Dict with:
        - 'radius_km': Recommended search radius
        - 'search_mode': 'wide', 'local', or 'default'
        - 'category': The category name
        - 'suggestion': User-facing suggestion text
    """
    # Case 1: Wide search category
    if category_name in WIDE_SEARCH_CATEGORIES:
        base_radius = WIDE_SEARCH_CATEGORIES[category_name]['default_radius_km']
        search_mode = 'wide'
    # Case 2: Local search category
    elif category_name in LOCAL_SEARCH_CATEGORIES:
        base_radius = LOCAL_SEARCH_CATEGORIES[category_name]['default_radius_km']
        search_mode = 'local'
    # Case 3: Unknown category
    else:
        base_radius = 50
        search_mode = 'default'

    # Adjust based on user's learned preferences
    if user_profile:
        user_pref = user_profile.preferred_max_distance_km
        # Average between category default and user preference
        adjusted_radius = (base_radius + user_pref) / 2
    else:
        adjusted_radius = base_radius

    return {
        'radius_km': adjusted_radius,
        'search_mode': search_mode,
        'category': category_name,
        'suggestion': _get_search_suggestion(search_mode, adjusted_radius),
    }


def _get_search_suggestion(mode, radius):
    """Generate a user-facing search suggestion message."""
    if mode == 'wide':
        return (
            f'🔍 Search expanded to {radius:.0f} km — '
            f'This type of product may require travel to inspect.'
        )
    elif mode == 'local':
        return (
            f'📍 Showing nearest results first (within {radius:.0f} km)'
        )
    else:
        return (
            f'📍 Searching within {radius:.0f} km — '
            f'You can adjust the range anytime.'
        )
```

---

### 5.3 Django Signals for Auto-Tracking

```python
# analytics/signals.py

"""
Django Signals for automatic interaction logging.
Connects existing model events to the analytics tracking system.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver

from products.models import Favorite, Review

from analytics.utils import log_user_event


@receiver(post_save, sender=Favorite)
def log_favorite_event(sender, instance, created, **kwargs):
    """Automatically log when a user favorites a product."""
    if created:
        log_user_event(
            user=instance.user,
            action='favorite',
            product=instance.product,
        )


@receiver(post_save, sender=Review)
def log_review_event(sender, instance, created, **kwargs):
    """
    Automatically log when a user writes a review.
    A review implies real contact happened, so we log it as 'contact'.
    """
    if created and instance.product:
        log_user_event(
            user=instance.user,
            action='contact',
            product=instance.product,
            metadata={'rating': instance.rating},
        )
```

---

### 5.4 App Configuration

```python
# analytics/apps.py

from django.apps import AppConfig


class AnalyticsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'analytics'
    verbose_name = 'Analytics & Recommendations'

    def ready(self):
        import analytics.signals  # noqa: F401
```

Don't forget to add `'analytics'` to `INSTALLED_APPS` in your `settings.py`:

```python
# settings.py (partial)

INSTALLED_APPS = [
    # ... existing apps ...
    'analytics',
]
```

Then run migrations:

```bash
python manage.py makemigrations analytics
python manage.py migrate
```

---

## 6. Phase 3: Future Enhancements (Post-Acceptance) 🟢

> **Add these after the project is accepted to keep evolving.**

### Near-Term (Month 3–4)

| Feature | Description |
|---------|-------------|
| Celery Integration | Async profile updates every hour instead of manual management command |
| GeoDjango + PostGIS | Real geographic distance calculations instead of estimated radius |
| REST API (DRF) | Mobile app endpoints for all recommendation and notification features |
| Real-time Negotiation | WebSocket-based live price bargaining between buyer and seller |

### Mid-Term (Month 5–6)

| Feature | Description |
|---------|-------------|
| TF-IDF Search | Better keyword matching using text frequency analysis |
| Collaborative Filtering | "Buyers who bought this also bought..." |
| Seller Badge System | Automated trust badges (Fast Responder, Competitive Pricing, Verified) |
| Seller Analytics Dashboard | Paid feature: views, peak hours, top products, engagement metrics |
| Push Notifications | Mobile push for price drops and new matches |

### Long-Term (Month 7+)

| Feature | Description |
|---------|-------------|
| Algerian Dialect NLP | Understanding search queries in Darja (Algerian Arabic dialect) |
| Fraud Detection | AI-powered detection of fake listings and scam accounts |
| Payment Integration | CIB and BaridiMob integration for optional secure deposits |
| A/B Testing Framework | Systematic optimization of recommendation algorithm weights |
| Content-Based Filtering | Image similarity matching using product photos |

---

## 7. Scoring Formula Breakdown

### Main Formula

$$Score = \sum_{i} (W_i \times S_i)$$

Where each component $S_i$ is normalized to 0–100 and weighted by $W_i$:

| Component | Weight ($W_i$) | Score ($S_i$) | Calculation |
|-----------|-------|-------|-------------|
| **Category Match** | 0.30 | 0–100 | `(user_cat_score / max_cat_score) × 100` |
| **Price Match** | 0.15 | 0–100 | 100 if exact range, 60 if adjacent, 20 otherwise |
| **Quality Rating** | 0.15 | 0–100 | `(avg_rating / 5) × 100 × confidence × quality_sensitivity` |
| **Recency** | 0.10 | 0–100 | 100 (≤1 day), 80 (≤7 days), 50 (≤30 days), decay after |
| **Popularity** | 0.10 | 0–100 | `min(weekly_interactions × 5, 100)` |
| **Seller Trust** | 0.10 | 0–100 | `(seller_avg_rating / 5) × 100 × confidence` + preferred bonus |
| **Negotiable** | 0.05 | 0–100 | 100 if negotiable, 30 if fixed price |
| **Promotion** | 0.05 | 0–100 | `min(discount_percentage × 2, 100)` |

### Time Decay Formula

$$Decay = 0.5^{(age\_days / half\_life\_days)}$$

- **Half-life**: 14 days (configurable)
- After 14 days → value drops to 50%
- After 28 days → value drops to 25%
- Floor: 1% (interactions never fully disappear within the 30-day window)

### Interaction Weights

| Action | Weight | Rationale |
|--------|--------|-----------|
| `view` | 1 | Passive — user just saw it |
| `click` | 2 | Intentional — user chose to look closer |
| `search` | 3 | Active — user is looking for something specific |
| `filter_price` | 3 | Active — user is narrowing by budget |
| `filter_dist` | 3 | Active — user cares about distance |
| `filter_wilaya` | 3 | Active — user has a specific region in mind |
| `filter_rating` | 3 | Active — user cares about quality |
| `share` | 4 | Social — user found it worth sharing |
| `favorite` | 5 | Strong — user explicitly saved it |
| `compare` | 6 | Very strong — user is comparing options seriously |
| `negotiate` | 8 | Very strong — user is ready to buy |
| `contact` | 10 | Strongest — user contacted the seller directly |

---

## 8. File Structure

```
analytics/
├── __init__.py
├── apps.py                  # App config with signal registration
├── models.py                # UserInterestProfile + InteractionLog
├── utils.py                 # log_user_event(), weights, price ranges, time decay
├── scoring.py               # Profile update algorithm (update_user_profile)
├── recommendations.py       # Main recommendation engine (get_recommended_products)
├── notifications.py         # Smart notification engine
├── adaptive_search.py       # Category-aware search radius logic
├── signals.py               # Auto-tracking via Django signals
├── admin.py                 # (Register models for Django admin)
├── management/
│   └── commands/
│       └── update_profiles.py  # Periodic profile update command
└── migrations/
    └── ...
```

### Integration Points in Existing Code

```python
# In products/views.py — Product Detail View
from analytics.utils import log_user_event

class ProductDetailView(DetailView):
    def get(self, request, *args, **kwargs):
        response = super().get(request, *args, **kwargs)
        log_user_event(request.user, 'view', product=self.object)
        return response


# In products/views.py — Contact Seller Action
def contact_seller(request, product_id):
    product = get_object_or_404(Product, id=product_id)
    log_user_event(request.user, 'contact', product=product)
    # ... rest of contact logic


# In products/views.py — Search View
def search_products(request):
    keyword = request.GET.get('q', '')
    log_user_event(request.user, 'search', metadata={'keyword': keyword})
    # ... rest of search logic


# In home/views.py — Homepage with Recommendations
from analytics.recommendations import get_recommended_products

def home(request):
    recommendations = []
    if request.user.is_authenticated:
        recommendations = get_recommended_products(request.user, limit=20)
    context = {'recommendations': recommendations}
    return render(request, 'home.html', context)
```

---

## 9. Implementation Timeline

| Week | Tasks | Deliverable |
|------|-------|-------------|
| **Week 1** | Create `analytics` app, models, migrations, `log_user_event()` | Database ready + interaction tracking functional |
| **Week 2** | Build `scoring.py` + `recommendations.py` + management command | Recommendation engine fully operational |
| **Week 3** | Add signals, integrate tracking into existing views, build API endpoints | Automatic tracking + recommendations visible in UI |
| **Week 4** | Build `notifications.py` + `adaptive_search.py` | Smart alerts + context-aware search radius |
| **Week 5** | Testing, seed realistic demo data, prepare presentation | **Demo-ready for Startup jury** |

### Priority Matrix

```
                    HIGH IMPACT
                        │
       ┌────────────────┼────────────────┐
       │                │                │
       │  Models +      │  Notification  │
       │  Logging +     │  Engine +      │
       │  Scoring +     │  Adaptive      │
       │  Recommendations│  Search       │
       │                │                │
       │  DO FIRST ✅   │  DO SECOND 🟡  │
       │  (Week 1-2)    │  (Week 3-4)    │
       │                │                │
  LOW ─┼────────────────┼────────────────┼─ HIGH
 EFFORT│                │                │  EFFORT
       │  Django Admin  │  Celery +      │
       │  Registration  │  GeoDjango +   │
       │                │  ML Models     │
       │  EASY WIN ✅   │  DO LATER 🟢   │
       │  (Anytime)     │  (Post-accept) │
       │                │                │
       └────────────────┼────────────────┘
                        │
                    LOW IMPACT
```

---

## 10. Startup Pitch Strengths

Use these points when presenting to the jury:

| Strength | Why It Matters |
|----------|---------------|
| **Custom algorithm for Algeria** | Not a generic ML library — a purpose-built formula that accounts for negotiation, distance, wilayas |
| **Cold Start solution** | New users see popular/trending products immediately — no empty screens |
| **Time Decay** | Old interactions lose value gradually — recommendations stay fresh and relevant |
| **Adaptive search radius** | Car → wide search, Phone → local search. **No Algerian platform does this** |
| **Result diversification** | No single seller dominates the results page |
| **Transparent match reasons** | User sees *why* a product was recommended → builds trust |
| **"See before you pay"** | The entire UX is built around in-person inspection — not blind e-commerce |
| **Built-in negotiation** | Digitizes how Algerians actually buy — instead of forcing fixed-price models |
| **Clear revenue model** | Freemium + paid promotions + paid alerts + seller analytics |
| **Scalable architecture** | Starts simple (management command) → scales to Celery + ML without rewriting |

---

## 11. Demo Preparation Tips

### 1. Create Realistic Seed Data

Build a management command that populates the database with real-looking Algerian market data:

```python
# Example seed data concept
# Phones from Oran, Cars from Algiers, Clothes from Setif, Real Estate from Constantine
# Multiple sellers per category with varying prices and ratings
```

### 2. Prepare a Live Demo Scenario

Walk the jury through a **live user journey**:

1. **New user signs up** → sees trending products (Cold Start)
2. **User browses phones** → system starts learning category interest
3. **User filters by price (5000–15000 DZD)** → system learns budget
4. **User favorites a Samsung phone** → strong interest signal
5. **Refresh homepage** → personalized recommendations appear with tags:
   - "Matches your interests"
   - "Fits your budget"
   - "Price negotiable"
6. **A seller drops the price** → user gets alert: "20% off on Samsung you viewed!"
7. **User searches for a car** → search radius expands to 500km automatically

### 3. Emphasize "Why Algeria Is Different"

The jury needs to hear:

- *"Existing platforms copied Western e-commerce models that don't fit Algeria."*
- *"Algerians want to negotiate, inspect, and buy face-to-face."*
- *"Our system doesn't change behavior — it digitizes and improves it."*
- *"A buyer searching for a phone needs local results. A buyer searching for a car needs national results. Our system adapts automatically."*

---

## Quick Reference: How to Call the Recommendation Engine

```python
from analytics.recommendations import get_recommended_products, get_similar_products
from analytics.utils import log_user_event
from analytics.notifications import SmartNotificationEngine
from analytics.adaptive_search import get_adaptive_search_radius

# 1. Log an interaction
log_user_event(request.user, 'view', product=my_product)

# 2. Get personalized recommendations
results = get_recommended_products(request.user, limit=20)
for item in results:
    print(item['product'].name, item['score'], item['match_reasons'])

# 3. Get similar products (for product detail page)
similar = get_similar_products(current_product, limit=10)

# 4. Check who to notify about a new product
notifications = SmartNotificationEngine.check_new_product(new_product)

# 5. Get adaptive search radius
radius_info = get_adaptive_search_radius('Cars', user_profile=profile)
print(radius_info['suggestion'])
# → "🔍 Search expanded to 500 km — This type of product may require travel."
```

---

> **Built with 🇩🇿 for Algeria — by understanding how Algerians actually buy and sell.**
