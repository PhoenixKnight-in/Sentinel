from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Any, Dict, Optional

import httpx
import asyncio


OVERPASS_URL = "https://overpass-api.de/api/interpreter"


@dataclass(frozen=True)
class CacheEntry:
    expires_at: float
    value: Dict[str, Any]


class OverpassClient:
    def __init__(self, base_url: str = OVERPASS_URL, ttl_seconds: int = 3600) -> None:
        self.base_url = base_url
        self.ttl_seconds = ttl_seconds
        self._cache: Dict[str, CacheEntry] = {}

    def _get_cached(self, key: str) -> Optional[Dict[str, Any]]:
        entry = self._cache.get(key)
        if not entry:
            return None
        if time.time() >= entry.expires_at:
            return None
        return entry.value

    def _get_stale(self, key: str) -> Optional[Dict[str, Any]]:
        entry = self._cache.get(key)
        return entry.value if entry else None

    def _set_cached(self, key: str, value: Dict[str, Any]) -> None:
        self._cache[key] = CacheEntry(expires_at=time.time() + self.ttl_seconds, value=value)

    async def query(self, query: str, *, timeout_s: float = 25.0) -> Dict[str, Any]:
        cached = self._get_cached(query)
        if cached is not None:
            return cached

        async with httpx.AsyncClient(timeout=timeout_s) as client:
            # Overpass is community-run and can rate-limit; do a light retry.
            data: Dict[str, Any] = {}
            for attempt in range(3):
                resp = await client.get(self.base_url, params={"data": query})
                if resp.status_code in (429, 502, 503, 504):
                    stale = self._get_stale(query)
                    if stale is not None:
                        return stale
                    if attempt < 2:
                        await asyncio.sleep(1.2 * (attempt + 1))
                        continue
                resp.raise_for_status()
                data = resp.json()
                break

        if isinstance(data, dict):
            self._set_cached(query, data)
        return data


def around(radius_m: int, lat: float, lon: float) -> str:
    return f"(around:{radius_m},{lat},{lon})"


def bbox(north: float, south: float, east: float, west: float) -> str:
    # Overpass bbox format: (south,west,north,east)
    return f"({south},{west},{north},{east})"


overpass = OverpassClient()

