from __future__ import annotations

from django.db.models import F

from .models import AbuseFlag


def record_abuse_signal(*, actor, signal_type: str, target_type: str, target_id: int | None, metadata: dict | None = None):
    metadata = metadata or {}
    row = AbuseFlag.objects.filter(
        actor=actor,
        signal_type=signal_type,
        target_type=target_type,
        target_id=target_id,
    ).first()
    if row is None:
        AbuseFlag.objects.create(
            actor=actor,
            signal_type=signal_type,
            target_type=target_type,
            target_id=target_id,
            count=1,
            metadata=metadata,
        )
        return

    AbuseFlag.objects.filter(id=row.id).update(
        count=F('count') + 1,
        metadata=metadata,
    )
