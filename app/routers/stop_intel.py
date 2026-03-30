from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, HTTPException, Query
import httpx

from ..data_store import store
from ..services.crowd_provider import DummyCrowdProvider
from ..services.geo import estimate_walking_time_min, grid_step_degrees, haversine_m
from ..services.osm_extract import element_lat_lon, element_name, get_tag
from ..services.overpass import around, bbox as overpass_bbox, overpass
from ..services.scoring import compute_incident_risk, compute_time_risk
from ..services.weather import get_current_weather
from ..schemas import Location


router = APIRouter()
crowd_provider = DummyCrowdProvider()


def _grade(score: float) -> str:
    if score >= 80:
        return "A"
    if score >= 70:
        return "B"
    if score >= 60:
        return "C"
    if score >= 45:
        return "D"
    return "F"


def _confidence(required_fields_present: int, required_fields_total: int) -> str:
    if required_fields_total <= 0:
        return "low"
    ratio = required_fields_present / required_fields_total
    if ratio >= 0.85:
        return "high"
    if ratio >= 0.6:
        return "medium"
    return "low"


async def _stop_meta_async(stop_id: str) -> Tuple[str, float, float]:
    s = store.get_stop(stop_id)
    if s:
        return (s.name or stop_id, s.location.lat, s.location.lon)

    if not stop_id.isdigit():
        raise HTTPException(
            status_code=404,
            detail="Stop not found (provide internal stop_id like STOP_1 or an OSM numeric node id)",
        )

    query = f"""
    [out:json][timeout:25];
    node({stop_id});
    out body;
    """
    data = await overpass.query(query)
    els = data.get("elements", []) if isinstance(data, dict) else []
    if not els:
        raise HTTPException(status_code=404, detail="OSM stop node not found")
    el = els[0]
    latlon = element_lat_lon(el)
    if not latlon:
        raise HTTPException(status_code=404, detail="OSM node missing coordinates")
    name = element_name(el) or f"OSM Node {stop_id}"
    return (name, latlon[0], latlon[1])


def _lamp_density_label(count: int, radius_m: int) -> str:
    # lamps per 100m (radius) heuristic
    per_100m = count / max(1.0, radius_m / 100.0)
    if per_100m >= 8:
        return "very_high"
    if per_100m >= 4:
        return "high"
    if per_100m >= 2:
        return "medium"
    return "low"

# Queries OpenStreetMap for physical features near a stop — street lamps, CCTV cameras
# shelters, and footpaths. It then computes an infrastructure_safety_score by 
# combining
#  coverage scores for lighting, CCTV, sidewalk presence, and shelter.
@router.get("/stops/{stop_id}/infrastructure")
async def stop_infrastructure(stop_id: str) -> Dict[str, Any]:
    stop_name, lat, lon = await _stop_meta_async(stop_id)
    radius_m = 5000

    q = f"""
    [out:json][timeout:25];
    (
    node["highway"="bus_stop"]{around(radius_m, lat, lon)};
    node["public_transport"="stop_position"]{around(radius_m, lat, lon)};
    node["public_transport"="platform"]{around(radius_m, lat, lon)};
    node["amenity"="bus_station"]{around(radius_m, lat, lon)};
    node["bus"="yes"]{around(radius_m, lat, lon)};
    );
    out body;
    """
    data = await overpass.query(q)
    elements: List[Dict[str, Any]] = data.get("elements", []) if isinstance(data, dict) else []

    lamps = [e for e in elements if get_tag(e, "highway") == "street_lamp"]
    cctv = [e for e in elements if get_tag(e, "man_made") == "surveillance"]
    stop_nodes = [e for e in elements if get_tag(e, "highway") == "bus_stop"]
    bus_station = [e for e in elements if get_tag(e, "amenity") == "bus_station"]
    ways = [e for e in elements if e.get("type") == "way"]

    lamp_types = sorted(
        {
            (get_tag(e, "lamp_type") or get_tag(e, "light_source") or get_tag(e, "light:method") or "unknown")
            for e in lamps
        }
    )
    lamp_count = len(lamps)
    density_per_100m = lamp_count / max(1.0, 100 / 100.0)
    coverage_score = min(100, int(30 + lamp_count * 4))

    cctv_count = len(cctv)
    cctv_score = min(100, int(25 + cctv_count * 18))

    # shelter tags often live on bus_stop nodes
    shelter_tags = {}
    if stop_nodes:
        shelter_tags = stop_nodes[0].get("tags", {}) if isinstance(stop_nodes[0].get("tags"), dict) else {}
    elif bus_station:
        shelter_tags = bus_station[0].get("tags", {}) if isinstance(bus_station[0].get("tags"), dict) else {}

    has_roof = str(shelter_tags.get("shelter", "")).lower() in ("yes", "roof")
    is_enclosed = str(shelter_tags.get("building", "")).lower() == "yes" or str(shelter_tags.get("enclosed", "")).lower() == "yes"
    has_seating = str(shelter_tags.get("bench", "")).lower() == "yes"

    # footpath availability: detect explicit sidewalks/footways nearby
    has_sidewalk = False
    surface = None
    for w in ways:
        tags = w.get("tags", {}) if isinstance(w.get("tags"), dict) else {}
        if tags.get("highway") in ("footway", "pedestrian", "path"):
            has_sidewalk = True
        if tags.get("sidewalk") in ("both", "left", "right", "yes"):
            has_sidewalk = True
        if not surface and isinstance(tags.get("surface"), str):
            surface = tags.get("surface")
    if not surface:
        surface = "unknown"

    foot_is_lit = lamp_count > 0

    infrastructure_safety_score = int(
        0.4 * coverage_score
        + 0.25 * cctv_score
        + 0.2 * (90 if has_sidewalk else 45)
        + 0.15 * (85 if has_roof else 55)
    )

    return {
        "stop_id": stop_id,
        "stop_name": stop_name,
        "location": {"lat": lat, "lng": lon},
        "infrastructure": {
            "street_lamps": {
                "count": lamp_count,
                "density_per_100m": round(lamp_count / 3.0, 1),  # rough heuristic
                "lamp_types": lamp_types,
                "coverage_score": coverage_score,
            },
            "cctv": {
                "count": cctv_count,
                "estimated_coverage_radius_m": 30,
                "coverage_score": cctv_score,
            },
            "shelter": {
                "has_roof": bool(has_roof or bus_station or stop_nodes),
                "is_enclosed": bool(is_enclosed),
                "has_seating": bool(has_seating),
            },
            "footpaths": {
                "has_sidewalk": bool(has_sidewalk),
                "surface": surface,
                "is_lit": bool(foot_is_lit),
            },
        },
        "infrastructure_safety_score": infrastructure_safety_score,
    }

#Looks for nearby emergency services (police, hospitals) and 
# active community presence (24/7 shops, ATMs, restaurants).
# Closer emergency services and more active businesses raise the score.

@router.get("/stops/{stop_id}/safety-context")
async def stop_safety_context(stop_id: str) -> Dict[str, Any]:
    stop_name, lat, lon = await _stop_meta_async(stop_id)

    q = f"""
    [out:json][timeout:25];
    (
      node["amenity"="police"]{around(1000, lat, lon)};
      node["amenity"~"hospital|clinic"]{around(2000, lat, lon)};
      node["amenity"="fire_station"]{around(2000, lat, lon)};
      node["amenity"="pharmacy"]{around(500, lat, lon)};
      node["shop"]["opening_hours"~"24/7"]{around(300, lat, lon)};
      node["amenity"="atm"]{around(300, lat, lon)};
      node["amenity"~"restaurant|fast_food|cafe"]{around(300, lat, lon)};
    );
    out body;
    """
    data = await overpass.query(q)
    elements: List[Dict[str, Any]] = data.get("elements", []) if isinstance(data, dict) else []

    def nodes_with(tag_key: str, tag_val: str) -> List[Dict[str, Any]]:
        return [e for e in elements if e.get("type") == "node" and get_tag(e, tag_key) == tag_val]

    police = nodes_with("amenity", "police")
    hospitals = [
        e
        for e in elements
        if e.get("type") == "node" and get_tag(e, "amenity") in ("hospital", "clinic")
    ]
    fire = nodes_with("amenity", "fire_station")
    pharmacies = nodes_with("amenity", "pharmacy")
    atms = nodes_with("amenity", "atm")
    restaurants = [
        e
        for e in elements
        if e.get("type") == "node"
        and get_tag(e, "amenity") in ("restaurant", "fast_food", "cafe")
    ]
    shops_24 = [
        e
        for e in elements
        if e.get("type") == "node"
        and get_tag(e, "shop") is not None
        and (get_tag(e, "opening_hours") or "").find("24/7") != -1
    ]

    def with_dist(el: Dict[str, Any]) -> Optional[Tuple[Dict[str, Any], float]]:
        ll = element_lat_lon(el)
        if not ll:
            return None
        return (el, haversine_m(lat, lon, ll[0], ll[1]))

    def nearest(elements_in: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        best = None
        for el in elements_in:
            wd = with_dist(el)
            if not wd:
                continue
            _, d = wd
            if best is None or d < best["distance_m"]:
                ll = element_lat_lon(el)
                best = {
                    "name": element_name(el) or "unknown",
                    "distance_m": int(round(d)),
                    "walking_time_min": estimate_walking_time_min(d),
                    "location": {"lat": ll[0], "lng": ll[1]} if ll else None,
                }
        return best

    nearest_police = nearest(police)
    nearest_hospital = nearest(hospitals)

    # response score: closer emergency services => higher score
    police_dist = nearest_police["distance_m"] if nearest_police else 2500
    hosp_dist = nearest_hospital["distance_m"] if nearest_hospital else 4000
    response_time_score = int(
        max(
            0,
            min(
                100,
                100
                - (police_dist / 20)  # 500m -> -25
                - (hosp_dist / 40),  # 2000m -> -50
            ),
        )
    )

    presence_score = int(
        min(
            100,
            40 + len(shops_24) * 8 + len(atms) * 10 + len(restaurants) * 3,
        )
    )
    community_activity_score = presence_score

    return {
        "stop_id": stop_id,
        "emergency_services": {
            "nearest_police_station": nearest_police,
            "nearest_hospital": nearest_hospital,
            "police_stations_within_1km": len(police),
            "hospitals_within_2km": len(hospitals),
        },
        "active_presence": {
            "shops_open_24hr": len(shops_24),
            "atms_within_300m": len(atms),
            "restaurants_within_300m": len(restaurants),
            "presence_score": presence_score,
        },
        "response_time_score": response_time_score,
        "community_activity_score": community_activity_score,
    }

#Combines lamp count from OSM with live weather data 
#(cloud cover, visibility, sunrise/sunset times) to determine whether
#a stop is well-lit right now.
@router.get("/stops/{stop_id}/lighting-status")
async def stop_lighting_status(stop_id: str, current_time: Optional[str] = None) -> Dict[str, Any]:
    stop_name, lat, lon = await _stop_meta_async(stop_id)

    now = datetime.now(tz=timezone.utc)
    if current_time:
        # Accept HH:MM in UTC for simplicity.
        try:
            hh, mm = current_time.split(":")
            now = now.replace(hour=int(hh), minute=int(mm), second=0, microsecond=0)
        except Exception:
            raise HTTPException(status_code=400, detail="current_time must be HH:MM (UTC)")

    q = f"""
    [out:json][timeout:25];
    (
      node["highway"="street_lamp"]{around(150, lat, lon)};
      node["highway"="bus_stop"]{around(60, lat, lon)};
      node["amenity"="bus_station"]{around(60, lat, lon)};
    );
    out body;
    """
    data = await overpass.query(q)
    elements: List[Dict[str, Any]] = data.get("elements", []) if isinstance(data, dict) else []

    lamps = [e for e in elements if get_tag(e, "highway") == "street_lamp"]
    lamp_count = len(lamps)
    lamp_types = sorted(
        {
            (get_tag(e, "lamp_type") or get_tag(e, "light_source") or "unknown")
            for e in lamps
        }
    )

    weather = await get_current_weather(lat, lon)
    sunset_iso = weather.get("sunset")
    sunrise_iso = weather.get("sunrise")
    # Determine night/day: if we have sunrise/sunset use those; else fall back to hour heuristic.
    is_night = now.hour >= 19 or now.hour <= 5
    if sunset_iso and sunrise_iso:
        try:
            sunset = datetime.fromisoformat(str(sunset_iso))
            sunrise = datetime.fromisoformat(str(sunrise_iso))
            # crude: if now is after sunset OR before sunrise
            is_night = (now >= sunset) or (now <= sunrise)
        except Exception:
            pass

    density_label = _lamp_density_label(lamp_count, 150)
    if density_label in ("very_high", "high"):
        estimated_lux = "bright"
    elif density_label == "medium":
        estimated_lux = "moderate"
    else:
        estimated_lux = "dim"

    cloud_cover = weather.get("cloud_cover_pct") or 0
    visibility_km = weather.get("visibility_km")
    weather_penalty = 0
    if isinstance(cloud_cover, int) and cloud_cover >= 70:
        weather_penalty += 10
    if isinstance(visibility_km, (int, float)) and visibility_km < 3:
        weather_penalty += 15

    base_score = min(100, 30 + lamp_count * 5)
    if is_night:
        lighting_safety_score = max(0, base_score - weather_penalty)
    else:
        lighting_safety_score = min(100, base_score + 10)

    recommendation = (
        "Well lit stop, safe for night travel"
        if lighting_safety_score >= 75
        else "Moderate lighting, stay alert"
        if lighting_safety_score >= 55
        else "Poor lighting, avoid if possible"
    )

    return {
        "stop_id": stop_id,
        "current_time": now.strftime("%H:%M"),
        "is_night": bool(is_night),
        "sun": {
            "sunset_was": sunset_iso,
            "sunrise_next": sunrise_iso,
        },
        "weather": {
            "condition": weather.get("condition"),
            "cloud_cover_pct": weather.get("cloud_cover_pct"),
            "visibility_km": weather.get("visibility_km"),
        },
        "physical_lighting": {
            "lamp_count_150m": lamp_count,
            "lamp_density": density_label.replace("_", " "),
            "lamp_types": lamp_types,
            "estimated_lux": estimated_lux,
        },
        "lighting_safety_score": lighting_safety_score,
        "recommendation": recommendation,
    }

#The master endpoint. It calls the three above endpoints internally,
#  then combines all scores with weights:
@router.get("/stops/{stop_id}/safety-score")
async def stop_master_safety_score(stop_id: str) -> Dict[str, Any]:
    stop_name, lat, lon = await _stop_meta_async(stop_id)
    # Use naive UTC to stay consistent with internal incident timestamps (seeded with datetime.utcnow()).
    now = datetime.utcnow().replace(microsecond=0)

    overpass_degraded = False
    try:
        infra = await stop_infrastructure(stop_id)
        context = await stop_safety_context(stop_id)
        lighting = await stop_lighting_status(stop_id, current_time=now.strftime("%H:%M"))
    except httpx.HTTPStatusError as e:
        if e.response is not None and e.response.status_code in (429, 502, 503, 504):
            overpass_degraded = True
            infra = {
                "infrastructure": {
                    "street_lamps": {"count": 0, "coverage_score": 40},
                    "cctv": {"count": 0},
                    "shelter": {"has_roof": False},
                    "footpaths": {"has_sidewalk": False},
                },
                "infrastructure_safety_score": 50,
                "stop_name": stop_name,
            }
            context = {
                "emergency_services": {"nearest_police_station": None, "nearest_hospital": None},
                "active_presence": {"shops_open_24hr": 0},
                "response_time_score": 55,
                "community_activity_score": 55,
            }
            lighting = {
                "lighting_safety_score": 55,
                "is_night": compute_time_risk(now) >= 0.5,
                "weather": {"condition": "unknown"},
            }
        else:
            raise

    # crowd + incidents from internal store if available; otherwise defaults
    crowd_density = await crowd_provider.get_crowd_density(
        location=Location(lat=lat, lon=lon),
        at=now,
    )
    time_risk = compute_time_risk(now)
    incidents = store.get_incidents_for_stop(stop_id)
    incident_risk = compute_incident_risk(incidents, now) if incidents is not None else 0.1

    lighting_score = int(lighting["lighting_safety_score"])
    emergency_score = int(context["response_time_score"])
    crowd_activity_score = int(context["community_activity_score"])
    infra_quality_score = int(infra["infrastructure_safety_score"])
    incident_score = int(round((1 - incident_risk) * 100))

    weights = {
        "lighting": 0.25,
        "emergency_proximity": 0.20,
        "crowd_activity": 0.20,
        "infrastructure_quality": 0.15,
        "incident_history": 0.20,
    }
    overall = (
        lighting_score * weights["lighting"]
        + emergency_score * weights["emergency_proximity"]
        + crowd_activity_score * weights["crowd_activity"]
        + infra_quality_score * weights["infrastructure_quality"]
        + incident_score * weights["incident_history"]
    )
    overall = int(round(max(0, min(100, overall))))

    alerts: List[str] = []
    if overpass_degraded:
        alerts.append("Overpass unavailable/rate-limited (using partial cached/fallback data)")
    if infra["infrastructure"]["cctv"]["count"] == 0:
        alerts.append("No CCTV nodes detected within 200m")
    if infra["infrastructure"]["street_lamps"]["count"] < 3 and lighting["is_night"]:
        alerts.append("Low street lamp density for night travel")
    if (context["active_presence"]["shops_open_24hr"] or 0) == 0:
        alerts.append("No 24/7 shops detected within 300m")
    if not infra["infrastructure"]["footpaths"]["has_sidewalk"]:
        alerts.append("Footpath/sidewalk presence unclear or missing near stop")

    required_total = 5
    required_present = 0
    required_present += 1 if infra else 0
    required_present += 1 if context else 0
    required_present += 1 if lighting else 0
    required_present += 1 if incidents is not None else 0
    required_present += 1 if crowd_density is not None else 0
    conf = _confidence(required_present, required_total)

    return {
        "stop_id": stop_id,
        "stop_name": stop_name,
        "timestamp": now.isoformat(),
        "overall_safety_score": overall,
        "grade": _grade(overall),
        "confidence": conf,
        "factor_breakdown": {
            "lighting": {
                "score": lighting_score,
                "weight": weights["lighting"],
                "status": "Well lit" if lighting_score >= 75 else "Moderate" if lighting_score >= 55 else "Poor",
                "source": "overpass + openweathermap" if lighting.get("weather", {}).get("condition") != "unknown" else "overpass",
            },
            "emergency_proximity": {
                "score": emergency_score,
                "weight": weights["emergency_proximity"],
                "status": "Police station within 500m"
                if (context.get("emergency_services", {}).get("nearest_police_station") or {}).get("distance_m", 9999) <= 500
                else "Police station farther than 500m",
                "source": "overpass",
            },
            "crowd_activity": {
                "score": crowd_activity_score,
                "weight": weights["crowd_activity"],
                "status": "Active area with shops" if crowd_activity_score >= 70 else "Quiet area",
                "source": "overpass + crowd_provider",
            },
            "infrastructure_quality": {
                "score": infra_quality_score,
                "weight": weights["infrastructure_quality"],
                "status": "Sheltered, paved footpath"
                if infra["infrastructure"]["shelter"]["has_roof"] and infra["infrastructure"]["footpaths"]["has_sidewalk"]
                else "Basic infrastructure",
                "source": "overpass",
            },
            "incident_history": {
                "score": incident_score,
                "weight": weights["incident_history"],
                "status": f"{len(incidents)} incidents in last 30 days" if incidents else "No recent incidents recorded",
                "source": "internal_db",
            },
        },
        "actionable_alerts": alerts,
        "safe_times": ["06:00–22:00"],
        "avoid_times": ["23:00–05:00"],
    }


@router.get("/stops/nearby")
async def stops_nearby(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: int = Query(500, ge=50, le=5000),
) -> Dict[str, Any]:
    q = f"""
    [out:json][timeout:25];
    node["highway"="bus_stop"]{around(radius_m, lat, lng)};
    out body;
    """
    try:
        data = await overpass.query(q, timeout_s=8.0)
        elements: List[Dict[str, Any]] = data.get("elements", []) if isinstance(data, dict) else []
    except httpx.HTTPError:
        elements = []

    stops_out = []
    best = None

    # Sort by distance and limit aggressively to reduce Overpass fan-out and avoid 429s.
    with_dist = []
    for el in elements:
        ll = element_lat_lon(el)
        if not ll:
            continue
        d = haversine_m(lat, lng, ll[0], ll[1])
        with_dist.append((el, d))
    with_dist.sort(key=lambda x: x[1])
    elements = [el for el, _ in with_dist[:12]]

    for el in elements:
        ll = element_lat_lon(el)
        if not ll:
            continue
        d = haversine_m(lat, lng, ll[0], ll[1])
        osm_id = str(el.get("id"))
        name = element_name(el) or f"Bus stop {osm_id}"

        # quick infra: lamps (150m), cctv (200m), nearest police (1km)
        q2 = f"""
        [out:json][timeout:25];
        (
          node["highway"="street_lamp"]{around(150, ll[0], ll[1])};
          node["man_made"="surveillance"]{around(200, ll[0], ll[1])};
          node["amenity"="police"]{around(1000, ll[0], ll[1])};
        );
        out body;
        """
        e2: List[Dict[str, Any]] = []
        try:
            d2 = await overpass.query(q2, timeout_s=8.0)
            e2 = d2.get("elements", []) if isinstance(d2, dict) else []
        except httpx.HTTPError:
            # Graceful fallback when Overpass rate limits/timeouts:
            # keep stop in result with conservative defaults instead of failing entire endpoint.
            e2 = []
        lamp_count = sum(1 for e in e2 if get_tag(e, "highway") == "street_lamp")
        cctv_count = sum(1 for e in e2 if get_tag(e, "man_made") == "surveillance")
        police_nodes = [e for e in e2 if get_tag(e, "amenity") == "police"]
        nearest_police_m = None
        if police_nodes:
            best_d = None
            for p in police_nodes:
                pll = element_lat_lon(p)
                if not pll:
                    continue
                pd = haversine_m(ll[0], ll[1], pll[0], pll[1])
                best_d = pd if best_d is None else min(best_d, pd)
            if best_d is not None:
                nearest_police_m = int(round(best_d))

        is_lit = lamp_count >= 3
        has_cctv = cctv_count >= 1

        # quick score
        lighting_score = min(100, 30 + lamp_count * 5)
        emergency_score = max(0, 100 - int((nearest_police_m or 2000) / 20))
        overall = int(round(0.5 * lighting_score + 0.5 * emergency_score))
        grade = _grade(overall)

        item = {
            "stop_id": osm_id,
            "stop_name": name,
            "distance_m": int(round(d)),
            "safety_score": overall,
            "grade": grade,
            "is_lit": bool(is_lit),
            "has_cctv": bool(has_cctv),
            "nearest_police_m": nearest_police_m if nearest_police_m is not None else 9999,
        }
        stops_out.append(item)

        if best is None or item["safety_score"] > best["safety_score"]:
            best = item

    stops_out.sort(key=lambda x: (-x["safety_score"], x["distance_m"]))

    recommendation = None
    if best:
        reason_bits = []
        if best["is_lit"]:
            reason_bits.append("Best lighting")
        if best["has_cctv"]:
            reason_bits.append("CCTV present")
        if best["nearest_police_m"] < 800:
            reason_bits.append(f"police station {best['nearest_police_m']}m away")
        recommendation = {
            "safest_nearby": best["stop_id"],
            "reason": ", ".join(reason_bits) if reason_bits else "Highest computed safety score nearby",
        }

    return {
        "user_location": {"lat": lat, "lng": lng},
        "radius_m": radius_m,
        "stops": stops_out,
        "recommendation": recommendation,
    }


@router.get("/routes/{route_id}/safety-profile")
async def route_safety_profile(route_id: str, direction: str = "unknown") -> Dict[str, Any]:
    route = store.get_route(route_id)

    stop_ids: List[str] = []
    route_name: str = route.name if route and route.name else route_id
    if route:
        stop_ids = route.stop_ids
    else:
        # Try OSM relation lookup by ref (bus route).
        # NOTE: Member ordering is not guaranteed; for production use GTFS or curated route-stop sequences.
        q = f"""
        [out:json][timeout:25];
        relation["route"="bus"]["ref"="{route_id}"];
        (._;>>;);
        node["highway"="bus_stop"](r);
        out body;
        """
        data = await overpass.query(q)
        els: List[Dict[str, Any]] = data.get("elements", []) if isinstance(data, dict) else []
        nodes = [e for e in els if e.get("type") == "node" and get_tag(e, "highway") == "bus_stop"]
        stop_ids = [str(n.get("id")) for n in nodes if n.get("id") is not None]
        if not stop_ids:
            raise HTTPException(
                status_code=404,
                detail="Route not found (internal store missing and no OSM bus relation ref match)",
            )

    stop_entries = []
    danger_segments = []
    scores = []

    prev_stop = None
    for idx, stop_id in enumerate(stop_ids, start=1):
        master = await stop_master_safety_score(stop_id)
        score = master["overall_safety_score"]
        scores.append(score)

        flags = []
        if master["factor_breakdown"]["lighting"]["score"] < 55:
            flags.append("poorly_lit")
        if any("No CCTV" in a for a in master["actionable_alerts"]):
            flags.append("no_cctv")
        if master["factor_breakdown"]["crowd_activity"]["score"] < 55:
            flags.append("isolated")

        stop_entries.append(
            {
                "sequence": idx,
                "stop_id": stop_id,
                "stop_name": master["stop_name"],
                "safety_score": score,
                "grade": master["grade"],
                "flags": flags,
            }
        )

        if prev_stop and (prev_stop["safety_score"] < 50 and score < 50):
            danger_segments.append(
                {
                    "from_stop": prev_stop["stop_id"],
                    "to_stop": stop_id,
                    "reason": "Consecutive low-safety stops (check lighting/footpaths)",
                    "severity": "high",
                }
            )
        prev_stop = stop_entries[-1]

    overall_route_score = int(round(sum(scores) / len(scores))) if scores else 0
    sorted_by_score = sorted(stop_entries, key=lambda x: -x["safety_score"])
    safest = [s["stop_id"] for s in sorted_by_score[:3]]
    risky = [s["stop_id"] for s in sorted(stop_entries, key=lambda x: x["safety_score"])[:3]]

    return {
        "route_id": route_id,
        "route_name": route_name,
        "direction": direction,
        "overall_route_score": overall_route_score,
        "total_stops": len(stop_entries),
        "stops": stop_entries,
        "danger_segments": danger_segments,
        "safest_stops": safest,
        "risky_stops": risky,
    }


@router.get("/area/heatmap")
async def area_heatmap(
    north: float = Query(..., ge=-90, le=90),
    south: float = Query(..., ge=-90, le=90),
    east: float = Query(..., ge=-180, le=180),
    west: float = Query(..., ge=-180, le=180),
    grid_m: int = Query(500, ge=100, le=2000),
) -> Dict[str, Any]:
    if south >= north or west >= east:
        raise HTTPException(status_code=400, detail="Invalid bbox bounds")

    lat_center = (north + south) / 2.0
    dlat, dlon = grid_step_degrees(lat_center, grid_m)

    # query all stops + lamps + key amenities in bbox once, then score per cell
    q = f"""
    [out:json][timeout:25];
    (
      node["highway"="bus_stop"]{overpass_bbox(north, south, east, west)};
      node["highway"="street_lamp"]{overpass_bbox(north, south, east, west)};
      node["amenity"="police"]{overpass_bbox(north, south, east, west)};
      node["amenity"="hospital"]{overpass_bbox(north, south, east, west)};
      node["amenity"="pharmacy"]{overpass_bbox(north, south, east, west)};
    );
    out body;
    """
    data = await overpass.query(q)
    elements: List[Dict[str, Any]] = data.get("elements", []) if isinstance(data, dict) else []

    stops = [e for e in elements if get_tag(e, "highway") == "bus_stop"]
    lamps = [e for e in elements if get_tag(e, "highway") == "street_lamp"]
    police = [e for e in elements if get_tag(e, "amenity") == "police"]
    hospitals = [e for e in elements if get_tag(e, "amenity") == "hospital"]
    pharmacies = [e for e in elements if get_tag(e, "amenity") == "pharmacy"]

    def in_cell(el: Dict[str, Any], cell_lat: float, cell_lon: float) -> bool:
        ll = element_lat_lon(el)
        if not ll:
            return False
        return abs(ll[0] - cell_lat) <= dlat / 2 and abs(ll[1] - cell_lon) <= dlon / 2

    cells = []
    lat = south + dlat / 2
    while lat < north:
        lon = west + dlon / 2
        while lon < east:
            stop_count = sum(1 for s in stops if in_cell(s, lat, lon))
            lamp_count = sum(1 for l in lamps if in_cell(l, lat, lon))
            police_count = sum(1 for p in police if in_cell(p, lat, lon))
            hosp_count = sum(1 for h in hospitals if in_cell(h, lat, lon))
            pharm_count = sum(1 for p in pharmacies if in_cell(p, lat, lon))

            lighting_score = min(100, 25 + lamp_count * 6)
            amenity_score = min(100, 30 + police_count * 25 + hosp_count * 15 + pharm_count * 10)
            stop_bonus = min(15, stop_count * 3)
            safety_score = int(round(0.55 * lighting_score + 0.45 * amenity_score + stop_bonus))
            safety_score = max(0, min(100, safety_score))

            dominant_risk = "low_lighting" if lighting_score < amenity_score else "no_emergency_services"
            if lighting_score >= 65 and amenity_score >= 65:
                dominant_risk = "none"

            cells.append(
                {
                    "center": {"lat": round(lat, 5), "lng": round(lon, 5)},
                    "safety_score": safety_score,
                    "stop_count": stop_count,
                    "dominant_risk": dominant_risk,
                }
            )

            lon += dlon
        lat += dlat

    return {
        "bbox": {"north": north, "south": south, "east": east, "west": west},
        "grid_resolution": f"{grid_m}m",
        "cells": cells,
        "legend": {
            "80-100": "Safe",
            "60-79": "Moderate",
            "40-59": "Caution",
            "0-39": "Avoid",
        },
    }

