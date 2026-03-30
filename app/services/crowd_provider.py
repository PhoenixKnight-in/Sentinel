from __future__ import annotations

from datetime import datetime
from typing import Protocol

import httpx

from ..schemas import Location


class CrowdProvider(Protocol):
    async def get_crowd_density(self, location: Location, at: datetime) -> float:  # pragma: no cover - protocol
        ...


class DummyCrowdProvider:
    """
    Placeholder provider that fakes crowd density based on time of day.

    Replace this with an implementation that calls a real, free API
    exposing crowd / footfall estimates.
    """

    async def get_crowd_density(self, location: Location, at: datetime) -> float:
        hour = at.hour
        if 7 <= hour < 9 or 17 <= hour < 19:
            return 0.9  # rush hour
        if 9 <= hour < 17:
            return 0.5  # moderate
        return 0.2  # off-peak


class HttpCrowdProvider:
    """
    Example of how you might integrate with a real HTTP API.
    Configure base_url and API key via environment or settings.
    """

    def __init__(self, base_url: str, api_key: str | None = None) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key

    async def get_crowd_density(self, location: Location, at: datetime) -> float:
        params = {
            "lat": location.lat,
            "lon": location.lon,
            "timestamp": at.isoformat(),
        }
        headers = {}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(f"{self.base_url}/crowd", params=params, headers=headers)
            resp.raise_for_status()
            data = resp.json()

        density = float(data.get("density", 0.5))
        return max(0.0, min(1.0, density))

