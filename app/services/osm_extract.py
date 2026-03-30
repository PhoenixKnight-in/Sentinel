from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple


def element_lat_lon(el: Dict[str, Any]) -> Optional[Tuple[float, float]]:
    if "lat" in el and "lon" in el:
        return float(el["lat"]), float(el["lon"])
    center = el.get("center")
    if isinstance(center, dict) and "lat" in center and "lon" in center:
        return float(center["lat"]), float(center["lon"])
    return None


def element_name(el: Dict[str, Any]) -> Optional[str]:
    tags = el.get("tags", {}) if isinstance(el.get("tags"), dict) else {}
    return tags.get("name") or tags.get("official_name") or tags.get("alt_name")


def filter_by_tags(elements: List[Dict[str, Any]], **must_match: str) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for el in elements:
        tags = el.get("tags", {}) if isinstance(el.get("tags"), dict) else {}
        ok = True
        for k, v in must_match.items():
            if tags.get(k) != v:
                ok = False
                break
        if ok:
            out.append(el)
    return out


def get_tag(el: Dict[str, Any], key: str) -> Optional[str]:
    tags = el.get("tags", {}) if isinstance(el.get("tags"), dict) else {}
    val = tags.get(key)
    return str(val) if val is not None else None

