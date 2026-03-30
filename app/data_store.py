from __future__ import annotations

import hashlib
from datetime import datetime
from typing import Dict, List, Optional

from .schemas import Incident, Location, RouteBase, StopBase


class InMemoryDataStore:
    """
    Simple in-memory store for demo purposes.

    - Keeps stops and routes.
    - Maintains a hash-chained list of incidents to show how
      tamper-evident storage could be structured before moving
      this to a real blockchain / decentralized backend.
    """

    def __init__(self) -> None:
        self.stops: Dict[str, StopBase] = {}
        self.routes: Dict[str, RouteBase] = {}
        self.incidents: List[Incident] = []

        self._seed_demo_data()

    def _seed_demo_data(self) -> None:
        self.stops["STOP_1"] = StopBase(
            stop_id="STOP_1",
            name="Central Station",
            location=Location(lat=51.5007, lon=-0.1246),
        )
        self.stops["STOP_2"] = StopBase(
            stop_id="STOP_2",
            name="Riverside Stop",
            location=Location(lat=51.5079, lon=-0.0877),
        )

        self.routes["ROUTE_A"] = RouteBase(
            route_id="ROUTE_A", name="Line A", stop_ids=["STOP_1", "STOP_2"]
        )

        # Seed a couple of incidents on STOP_1 and ROUTE_A
        self.add_incident(
            stop_id="STOP_1",
            route_id="ROUTE_A",
            severity=3,
            description="Harassment reported on platform.",
            timestamp=datetime.utcnow(),
        )

    def get_stop(self, stop_id: str) -> Optional[StopBase]:
        return self.stops.get(stop_id)

    def get_route(self, route_id: str) -> Optional[RouteBase]:
        return self.routes.get(route_id)

    def get_incidents_for_stop(self, stop_id: str) -> List[Incident]:
        return [i for i in self.incidents if i.stop_id == stop_id]

    def get_incidents_for_route(self, route_id: str) -> List[Incident]:
        return [i for i in self.incidents if i.route_id == route_id]

    def _compute_hash(self, payload: str, prev_hash: Optional[str]) -> str:
        m = hashlib.sha256()
        if prev_hash:
            m.update(prev_hash.encode("utf-8"))
        m.update(payload.encode("utf-8"))
        return m.hexdigest()

    def add_incident(
        self,
        *,
        stop_id: Optional[str],
        route_id: Optional[str],
        severity: int,
        description: Optional[str],
        timestamp: datetime,
    ) -> Incident:
        prev_hash = self.incidents[-1].hash if self.incidents else None
        payload = f"{stop_id}|{route_id}|{severity}|{description}|{timestamp.isoformat()}"
        new_hash = self._compute_hash(payload, prev_hash)

        incident = Incident(
            incident_id=f"INC_{len(self.incidents) + 1}",
            stop_id=stop_id,
            route_id=route_id,
            timestamp=timestamp,
            severity=severity,
            description=description,
            prev_hash=prev_hash,
            hash=new_hash,
        )
        self.incidents.append(incident)
        return incident


store = InMemoryDataStore()

