from __future__ import annotations

from datetime import datetime, time, timezone
from typing import Iterable, Optional

from .. import schemas


def _classify_level(score: float) -> str:
    if score >= 70:
        return "LOW"
    if score >= 40:
        return "MEDIUM"
    return "HIGH"


def compute_time_risk(dt: datetime) -> float:
    """
    Simple heuristic: late night / early morning is riskier.
    0.0 = very safe time, 1.0 = very risky time.
    """
    hour = dt.hour
    if 6 <= hour < 20:
        return 0.2  # daytime
    if 20 <= hour < 23:
        return 0.5  # evening
    return 0.9  # late night


def compute_incident_risk(incidents: Iterable[schemas.Incident], now: datetime) -> float:
    """
    Very simple model:
    - recent, severe incidents contribute most
    - look back 30 days
    """
    def to_utc_naive(dt: datetime) -> datetime:
        if dt.tzinfo is None:
            return dt
        return dt.astimezone(timezone.utc).replace(tzinfo=None)

    now_n = to_utc_naive(now)
    lookback_days = 30
    recent = [
        i
        for i in incidents
        if 0 <= (now_n - to_utc_naive(i.timestamp)).days <= lookback_days
    ]
    if not recent:
        return 0.1

    # Weight severity and recency
    total = 0.0
    for i in recent:
        days_ago = (now_n - to_utc_naive(i.timestamp)).days
        recency_weight = max(0.1, 1 - days_ago / lookback_days)
        total += i.severity * recency_weight

    # Normalize roughly into [0, 1]
    # Assume 10 as a "very bad" aggregate level for this period.
    normalized = min(1.0, total / 10.0)
    return normalized


def compute_safety_score(
    *,
    target_type: str,
    target_id: str,
    crowd_density: float,
    lighting_score: float,
    time_risk: float,
    incident_risk: float,
    now: Optional[datetime] = None,
) -> schemas.SafetyScore:
    """
    Combine factors into a single 0-100 score.
    Higher score = safer.
    """
    if now is None:
        now = datetime.utcnow()

    # Convert risk-style factors to safety-style
    crowd_safety = 1 - crowd_density  # too crowded is less safe (stampede/harassment)
    time_safety = 1 - time_risk
    incident_safety = 1 - incident_risk

    # Weights can be tuned
    w_crowd = 0.25
    w_light = 0.25
    w_time = 0.2
    w_incident = 0.3

    composite_0_1 = (
        w_crowd * crowd_safety
        + w_light * lighting_score
        + w_time * time_safety
        + w_incident * incident_safety
    )
    score_0_100 = max(0.0, min(100.0, composite_0_1 * 100))

    factors = schemas.SafetyFactors(
        crowd_density=crowd_density,
        lighting_score=lighting_score,
        time_risk=time_risk,
        incident_risk=incident_risk,
    )

    return schemas.SafetyScore(
        target_type=target_type,
        target_id=target_id,
        score=score_0_100,
        level=_classify_level(score_0_100),
        factors=factors,
        generated_at=now,
    )

