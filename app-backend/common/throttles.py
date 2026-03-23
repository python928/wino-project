from rest_framework.throttling import ScopedRateThrottle


class BurstScopedRateThrottle(ScopedRateThrottle):
    """Scoped throttle with standard DRF cache-key behavior."""

    scope_attr = 'throttle_scope'
