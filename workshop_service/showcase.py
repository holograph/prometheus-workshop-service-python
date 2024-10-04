from fastapi import APIRouter
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, Gauge

router = APIRouter(prefix="/showcase")

counter = Counter("my_count", "Event count", ["my_label"])
histogram = Histogram("my_duration", "Event duration", buckets=[10, 100, 1000, 2000, 5000])
gauge = Gauge("my_value", "Some stateful value")

@router.get("/count/{label}")
def count(label: str) -> dict:
    counter.labels(my_label=label).inc(1)
    return {"status": "ok"}


@router.get("/duration/{length_ms}")
def duration(length_ms: int) -> dict:
    histogram.observe(length_ms)
    return {"status": "ok"}

class GaugeData(BaseModel):
    value: int

@router.put("/gauge")
def gauge_value(data: GaugeData) -> dict:
    gauge.set(data.value)
    return {"status": "ok"}
