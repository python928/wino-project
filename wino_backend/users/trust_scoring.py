from __future__ import annotations

from dataclasses import dataclass
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from django.utils import timezone

from analytics.models import InteractionLog
from catalog.models import ProductReport, Review
from users.models import StoreReport, TrustSettings

User = get_user_model()


@dataclass
class ScoreResult:
    score: int
    level: str
    is_low_credibility: bool
    evidence_snapshot: dict
    reporter_reputation: int | None = None


def _level(score: int) -> str:
    if score >= 70:
        return 'high'
    if score >= 40:
        return 'medium'
    return 'low'


def _bounded(value: float) -> int:
    return max(0, min(100, int(round(value))))


def _seconds_since(dt):
    if not dt:
        return None
    return max(0, int((timezone.now() - dt).total_seconds()))


def _reporter_reputation(reporter: User, settings: TrustSettings) -> int:
    total_reports = (
        StoreReport.objects.filter(reporter=reporter).count()
        + ProductReport.objects.filter(reporter=reporter).count()
    )
    rejected_reports = (
        StoreReport.objects.filter(reporter=reporter, status=StoreReport.STATUS_REJECTED).count()
        + ProductReport.objects.filter(reporter=reporter, status=ProductReport.STATUS_REJECTED).count()
    )
    if total_reports == 0:
        return int(settings.reporter_reputation_default)
    quality_ratio = 1.0 - (rejected_reports / total_reports)
    base = settings.reporter_reputation_default * quality_ratio
    return _bounded(base)


def score_store_report(reporter: User, store: User) -> ScoreResult:
    settings = TrustSettings.get_settings()
    now = timezone.now()
    recent_cutoff = now - timedelta(days=30)

    visits_qs = InteractionLog.objects.filter(
        user=reporter,
        timestamp__gte=recent_cutoff,
        metadata__store_id=store.id,
    )
    visits_count = visits_qs.filter(action__in=['store_click', 'view', 'click']).count()
    meaningful_actions = visits_qs.filter(action__in=['favorite', 'contact', 'share', 'follow_store', 'rate']).count()
    last_event = visits_qs.order_by('-timestamp').first()
    seconds_since_last_event = _seconds_since(getattr(last_event, 'timestamp', None))

    account_age_days = max(0, (now - reporter.date_joined).days)
    reputation = _reporter_reputation(reporter, settings)

    interaction_component = 0.0
    if visits_count == 0:
        interaction_component = 0.0
    elif meaningful_actions > 0:
        interaction_component = 1.0
    else:
        interaction_component = min(0.7, visits_count / 5.0)

    recency_component = 1.0 if seconds_since_last_event is not None and seconds_since_last_event <= 86400 else 0.4
    account_age_component = min(1.0, account_age_days / 60.0)
    reputation_component = reputation / 100.0

    score = (
        interaction_component * settings.report_weight_interactions
        + recency_component * settings.report_weight_recency
        + reputation_component * settings.report_weight_reputation
        + account_age_component * settings.report_weight_account_age
    )

    if visits_count == 0:
        score -= 30
    if seconds_since_last_event is not None and seconds_since_last_event < settings.report_quick_submit_seconds:
        score -= 20

    final_score = _bounded(score)
    level = _level(final_score)

    return ScoreResult(
        score=final_score,
        level=level,
        is_low_credibility=final_score < 40,
        reporter_reputation=reputation,
        evidence_snapshot={
            'store_id': store.id,
            'visits_count_30d': visits_count,
            'meaningful_actions_30d': meaningful_actions,
            'seconds_since_last_event': seconds_since_last_event,
            'account_age_days': account_age_days,
            'reporter_reputation': reputation,
            'version': 'v1',
        },
    )


def score_product_report(reporter: User, product_id: int, store_id: int) -> ScoreResult:
    settings = TrustSettings.get_settings()
    now = timezone.now()
    recent_cutoff = now - timedelta(days=30)

    product_events = InteractionLog.objects.filter(
        user=reporter,
        timestamp__gte=recent_cutoff,
        metadata__product_id=product_id,
    )
    store_events = InteractionLog.objects.filter(
        user=reporter,
        timestamp__gte=recent_cutoff,
        metadata__store_id=store_id,
    )

    product_visits = product_events.filter(action__in=['view', 'click']).count()
    store_visits = store_events.filter(action__in=['store_click', 'view']).count()
    meaningful_actions = (
        product_events.filter(action__in=['favorite', 'contact', 'share', 'rate']).count()
        + store_events.filter(action__in=['favorite', 'contact', 'share', 'follow_store']).count()
    )

    last_event = product_events.order_by('-timestamp').first() or store_events.order_by('-timestamp').first()
    seconds_since_last_event = _seconds_since(getattr(last_event, 'timestamp', None))

    account_age_days = max(0, (now - reporter.date_joined).days)
    reputation = _reporter_reputation(reporter, settings)

    interaction_component = 0.0
    total_visits = product_visits + store_visits
    if total_visits == 0:
        interaction_component = 0.0
    elif meaningful_actions > 0:
        interaction_component = 1.0
    else:
        interaction_component = min(0.7, total_visits / 6.0)

    recency_component = 1.0 if seconds_since_last_event is not None and seconds_since_last_event <= 86400 else 0.4
    account_age_component = min(1.0, account_age_days / 60.0)
    reputation_component = reputation / 100.0

    score = (
        interaction_component * settings.report_weight_interactions
        + recency_component * settings.report_weight_recency
        + reputation_component * settings.report_weight_reputation
        + account_age_component * settings.report_weight_account_age
    )

    if total_visits == 0:
        score -= 30
    if seconds_since_last_event is not None and seconds_since_last_event < settings.report_quick_submit_seconds:
        score -= 20

    final_score = _bounded(score)
    level = _level(final_score)

    return ScoreResult(
        score=final_score,
        level=level,
        is_low_credibility=final_score < 40,
        reporter_reputation=reputation,
        evidence_snapshot={
            'product_id': product_id,
            'store_id': store_id,
            'product_visits_30d': product_visits,
            'store_visits_30d': store_visits,
            'meaningful_actions_30d': meaningful_actions,
            'seconds_since_last_event': seconds_since_last_event,
            'account_age_days': account_age_days,
            'reporter_reputation': reputation,
            'version': 'v1',
        },
    )


def score_review_credibility(user: User, store_id: int | None, product_id: int | None, rating: int) -> ScoreResult:
    settings = TrustSettings.get_settings()
    now = timezone.now()
    recent_cutoff = now - timedelta(days=30)

    events = InteractionLog.objects.filter(user=user, timestamp__gte=recent_cutoff)
    if product_id is not None:
        events = events.filter(metadata__product_id=product_id)
    elif store_id is not None:
        events = events.filter(metadata__store_id=store_id)

    total_interactions = events.count()
    meaningful_actions = events.filter(action__in=['favorite', 'contact', 'share', 'follow_store', 'click']).count()
    last_event = events.order_by('-timestamp').first()
    seconds_since_last_event = _seconds_since(getattr(last_event, 'timestamp', None))

    account_age_days = max(0, (now - user.date_joined).days)

    historical_ratings = Review.objects.filter(user=user).exclude(rating__isnull=True)
    negative_count = historical_ratings.filter(rating__lte=2).count()
    total_count = historical_ratings.count()
    negative_ratio = (negative_count / total_count) if total_count else 0.0

    dwell_component = 1.0
    if seconds_since_last_event is None:
        dwell_component = 0.0
    elif seconds_since_last_event < settings.review_quick_submit_seconds:
        dwell_component = 0.2

    interaction_component = min(1.0, meaningful_actions / max(1, settings.minimum_interactions_for_high_credibility))
    account_age_component = min(1.0, account_age_days / 60.0)
    history_component = 1.0 - min(1.0, negative_ratio)

    score = (
        dwell_component * settings.review_weight_dwell
        + interaction_component * settings.review_weight_interactions
        + account_age_component * settings.review_weight_account_age
        + history_component * settings.review_weight_history
    )

    if rating <= 2 and dwell_component < 0.4 and meaningful_actions == 0:
        score -= 25

    final_score = _bounded(score)
    level = _level(final_score)

    return ScoreResult(
        score=final_score,
        level=level,
        is_low_credibility=final_score < 40,
        evidence_snapshot={
            'store_id': store_id,
            'product_id': product_id,
            'rating': rating,
            'interactions_30d': total_interactions,
            'meaningful_actions_30d': meaningful_actions,
            'seconds_since_last_event': seconds_since_last_event,
            'account_age_days': account_age_days,
            'historical_negative_ratio': round(negative_ratio, 4),
            'version': 'v1',
        },
    )


def high_risk_snapshot(limit: int = 20) -> dict:
    """Admin moderation intelligence snapshot for products and stores."""
    store_rows = (
        StoreReport.objects.filter(status=StoreReport.STATUS_PENDING)
        .values('store_id')
        .annotate(
            report_count=Count('id'),
            effective_report_score=Count('id', filter=Q(is_low_credibility=False)),
        )
        .order_by('-effective_report_score', '-report_count')[:limit]
    )

    product_rows = (
        ProductReport.objects.filter(status=ProductReport.STATUS_PENDING)
        .values('product_id')
        .annotate(
            report_count=Count('id'),
            effective_report_score=Count('id', filter=Q(is_low_credibility=False)),
        )
        .order_by('-effective_report_score', '-report_count')[:limit]
    )

    store_negative_reviews = (
        Review.objects.filter(rating__lte=2)
        .values('store_id')
        .annotate(
            negative_reviews=Count('id'),
            effective_negative_rating_score=Count('id', filter=Q(is_low_credibility=False)),
        )
    )
    store_neg_map = {row['store_id']: row for row in store_negative_reviews if row['store_id'] is not None}

    product_negative_reviews = (
        Review.objects.filter(rating__lte=2)
        .values('product_id')
        .annotate(
            negative_reviews=Count('id'),
            effective_negative_rating_score=Count('id', filter=Q(is_low_credibility=False)),
        )
    )
    product_neg_map = {row['product_id']: row for row in product_negative_reviews if row['product_id'] is not None}

    high_risk_stores = []
    for row in store_rows:
        neg = store_neg_map.get(row['store_id'], {'negative_reviews': 0, 'effective_negative_rating_score': 0})
        priority = row['effective_report_score'] + neg['effective_negative_rating_score']
        high_risk_stores.append(
            {
                'store_id': row['store_id'],
                'report_count': row['report_count'],
                'effective_report_score': row['effective_report_score'],
                'negative_reviews': neg['negative_reviews'],
                'effective_negative_rating_score': neg['effective_negative_rating_score'],
                'moderation_priority_score': priority,
                'reason_breakdown': {
                    'reports_pending': row['report_count'],
                    'credible_reports': row['effective_report_score'],
                    'credible_negative_ratings': neg['effective_negative_rating_score'],
                },
            }
        )

    high_risk_products = []
    for row in product_rows:
        neg = product_neg_map.get(row['product_id'], {'negative_reviews': 0, 'effective_negative_rating_score': 0})
        priority = row['effective_report_score'] + neg['effective_negative_rating_score']
        high_risk_products.append(
            {
                'product_id': row['product_id'],
                'report_count': row['report_count'],
                'effective_report_score': row['effective_report_score'],
                'negative_reviews': neg['negative_reviews'],
                'effective_negative_rating_score': neg['effective_negative_rating_score'],
                'moderation_priority_score': priority,
                'reason_breakdown': {
                    'reports_pending': row['report_count'],
                    'credible_reports': row['effective_report_score'],
                    'credible_negative_ratings': neg['effective_negative_rating_score'],
                },
            }
        )

    high_risk_stores.sort(key=lambda x: x['moderation_priority_score'], reverse=True)
    high_risk_products.sort(key=lambda x: x['moderation_priority_score'], reverse=True)

    return {
        'high_risk_stores': high_risk_stores,
        'high_risk_products': high_risk_products,
        'generated_at': timezone.now().isoformat(),
        'explainability': 'Scores combine seriousness-weighted reports and credibility-weighted low ratings.',
    }


def evaluate_store_verification(store: User) -> dict:
    """Evaluate store verification eligibility and update status fields."""
    trust = TrustSettings.get_settings()

    credible_positive = Review.objects.filter(
        store=store,
        rating__gte=4,
        is_low_credibility=False,
    ).count()
    credible_negative = Review.objects.filter(
        store=store,
        rating__lte=2,
        is_low_credibility=False,
    ).count()
    total_credible = credible_positive + credible_negative
    negative_ratio_percent = (credible_negative / total_credible * 100.0) if total_credible else 0.0

    account_age_days = max(0, (timezone.now() - store.date_joined).days)
    unresolved_severe_reports = StoreReport.objects.filter(
        store=store,
        status=StoreReport.STATUS_PENDING,
        seriousness_level=StoreReport.LEVEL_HIGH,
        is_low_credibility=False,
    ).count()

    eligible = (
        credible_positive >= int(trust.verified_min_credible_positive_reviews or 10)
        and negative_ratio_percent <= float(trust.verified_max_credible_negative_ratio_percent or 20)
        and account_age_days >= int(trust.verified_min_account_age_days or 30)
        and unresolved_severe_reports == 0
    )

    if eligible:
        if bool(trust.auto_verify_eligible_stores):
            store.verification_status = 'verified'
            store.is_verified = True
            store.verified_at = timezone.now()
            if not store.verification_note:
                store.verification_note = 'Auto-verified by trust policy.'
            store.save(update_fields=['verification_status', 'is_verified', 'verified_at', 'verification_note'])
        elif store.verification_status in ['none', 'rejected']:
            store.verification_status = 'eligible'
            store.is_verified = False
            store.save(update_fields=['verification_status', 'is_verified'])
    else:
        if store.verification_status in ['eligible', 'pending']:
            store.verification_status = 'none'
            store.is_verified = False
            store.save(update_fields=['verification_status', 'is_verified'])

    return {
        'store_id': store.id,
        'eligible': eligible,
        'auto_mode': bool(trust.auto_verify_eligible_stores),
        'credible_positive': credible_positive,
        'credible_negative': credible_negative,
        'negative_ratio_percent': round(negative_ratio_percent, 2),
        'account_age_days': account_age_days,
        'unresolved_severe_reports': unresolved_severe_reports,
        'status': store.verification_status,
        'is_verified': store.is_verified,
    }
