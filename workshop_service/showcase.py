from fastapi import APIRouter
from pydantic import BaseModel
from opentelemetry.metrics import get_meter

router = APIRouter(prefix="/showcase")
meter = get_meter("showcase")
counter = meter.create_counter("my_count", description="Event count")
histogram = meter.create_histogram("my_duration", unit="ms", description="Event duration")
gauge = meter.create_gauge("my_value", description="Some stateful value")

@router.get("/count/{label}")
def count(label: str) -> dict:
    counter.add(1, {"my_label": label})
    return {"status": "ok"}


@router.get("/duration/{length_ms}")
def duration(length_ms: int) -> dict:
    histogram.record(length_ms)
    return {"status": "ok"}

class GaugeData(BaseModel):
    value: int

@router.put("/gauge")
def gauge_value(data: GaugeData) -> dict:
    gauge.set(data.value)
    return {"status": "ok"}
