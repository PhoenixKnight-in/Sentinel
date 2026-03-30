from datetime import datetime, time
from typing import List, Optional

from pydantic import BaseModel, Field


class Location(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)


class StopBase(BaseModel):
    stop_id: str
    name: Optional[str] = None
    location: Location


class RouteBase(BaseModel):
    route_id: str
    name: Optional[str] = None
    stop_ids: List[str]


class Incident(BaseModel):
    incident_id: str
    stop_id: Optional[str] = None
    route_id: Optional[str] = None
    timestamp: datetime
    severity: int = Field(..., ge=1, le=5)
    description: Optional[str] = None
    prev_hash: Optional[str] = None
    hash: str


class SafetyFactors(BaseModel):
    crowd_density: float = Field(..., ge=0, le=1, description="0=empty, 1=packed")
    lighting_score: float = Field(..., ge=0, le=1, description="0=dark, 1=well-lit")
    time_risk: float = Field(..., ge=0, le=1, description="0=low risk time, 1=high risk time")
    incident_risk: float = Field(..., ge=0, le=1, description="0=no incidents, 1=very unsafe history")


class SafetyScore(BaseModel):
    target_type: str = Field(..., description="stop or route")
    target_id: str
    score: float = Field(..., ge=0, le=100)
    level: str = Field(..., description="LOW, MEDIUM, HIGH")
    factors: SafetyFactors
    generated_at: datetime


class StopSafetyRequest(BaseModel):
    stop_id: str
    current_time: datetime


class RouteSafetyRequest(BaseModel):
    route_id: str
    current_time: datetime


class AdHocSafetyRequest(BaseModel):
    location: Location
    current_time: datetime
    lighting_score: Optional[float] = Field(
        None, ge=0, le=1, description="If provided, overrides default lighting model"
    )

