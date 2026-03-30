from __future__ import annotations

import math
from typing import Iterable, Optional, Tuple


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Great-circle distance between two points on Earth (meters).
    """
    r = 6371000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = (
        math.sin(dphi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return r * c


def estimate_walking_time_min(distance_m: float, speed_kmh: float = 4.5) -> int:
    # speed_kmh -> meters per minute
    m_per_min = (speed_kmh * 1000) / 60
    return max(1, int(round(distance_m / m_per_min)))


def grid_step_degrees(lat_center: float, step_m: float) -> Tuple[float, float]:
    """
    Approximate conversion from meters to degrees at given latitude.
    Returns (dlat, dlon).
    """
    dlat = step_m / 111_320.0
    dlon = step_m / (111_320.0 * math.cos(math.radians(lat_center)) + 1e-9)
    return dlat, dlon


def nearest_point(
    origin_lat: float,
    origin_lon: float,
    points: Iterable[Tuple[str, float, float]],
) -> Optional[Tuple[str, float]]:
    """
    points: iterable of (name, lat, lon)
    returns: (name, distance_m)
    """
    best = None
    for name, lat, lon in points:
        d = haversine_m(origin_lat, origin_lon, lat, lon)
        if best is None or d < best[1]:
            best = (name, d)
    return best

