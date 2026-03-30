from fastapi import FastAPI

from .routers import stop_intel


def create_app() -> FastAPI:
    app = FastAPI(
        title="Public Transport Safety Scoring API",
        version="0.1.0",
        description=(
            "Real-time safety scoring for public transport routes and stops, "
            "combining crowd density, lighting, time-of-day, and incident history."
        ),
    )

    app.include_router(stop_intel.router, tags=["osm-intel"])

    @app.get("/")
    async def root() -> dict:
        return {
            "message": "Public Transport Safety Scoring API",
            "docs": "/docs",
            "health": "/health",
        }

    @app.get("/health")
    async def health_check() -> dict:
        return {"status": "ok"}

    return app


app = create_app()

