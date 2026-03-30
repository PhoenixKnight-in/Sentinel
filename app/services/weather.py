from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import httpx


OPENWEATHER_BASE = "https://api.openweathermap.org/data/2.5"


def _get_api_key() -> Optional[str]:
    return os.getenv("OPENWEATHER_API_KEY")


async def get_current_weather(lat: float, lon: float) -> Dict[str, Any]:
    """
    Returns a normalized weather payload.
    If OPENWEATHER_API_KEY is missing, returns a safe fallback with low confidence.
    """
    api_key = _get_api_key()
    if not api_key:
        # Fallback: treat as clear with unknown visibility.
        return {
            "source": "fallback",
            "condition": "unknown",
            "cloud_cover_pct": 0,
            "visibility_km": None,
            "sunset": None,
            "sunrise": None,
        }

    params = {"lat": lat, "lon": lon, "appid": api_key, "units": "metric"}
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(f"{OPENWEATHER_BASE}/weather", params=params)
        resp.raise_for_status()
        data = resp.json()

    condition = "unknown"
    if isinstance(data.get("weather"), list) and data["weather"]:
        condition = data["weather"][0].get("main") or data["weather"][0].get("description") or "unknown"

    clouds = int(data.get("clouds", {}).get("all", 0) or 0)
    visibility_m = data.get("visibility")
    visibility_km = None
    if isinstance(visibility_m, (int, float)):
        visibility_km = round(float(visibility_m) / 1000.0, 1)

    sys = data.get("sys", {}) if isinstance(data.get("sys"), dict) else {}
    sunrise = sys.get("sunrise")
    sunset = sys.get("sunset")
    sunrise_iso = (
        datetime.fromtimestamp(sunrise, tz=timezone.utc).isoformat() if isinstance(sunrise, (int, float)) else None
    )
    sunset_iso = (
        datetime.fromtimestamp(sunset, tz=timezone.utc).isoformat() if isinstance(sunset, (int, float)) else None
    )

    return {
        "source": "openweathermap",
        "condition": condition.lower(),
        "cloud_cover_pct": clouds,
        "visibility_km": visibility_km,
        "sunrise": sunrise_iso,
        "sunset": sunset_iso,
    }

