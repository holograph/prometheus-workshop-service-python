import logging

from pydantic import BaseModel
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Counter, Histogram, Gauge

app = FastAPI()
logging.basicConfig(level=logging.INFO)
Instrumentator().expose(app)

counter = Counter("my_count", "Event count", ["my_label"])
histogram = Histogram("my_duration", "Event duration", buckets=[10, 100, 1000, 2000, 5000])
gauge = Gauge("my_value", "Some stateful value")

@app.get("/count/{label}")
def count(label: str) -> dict:
    counter.labels(my_label=label).inc(1)
    return {"status": "ok"}


@app.get("/duration/{length_ms}")
def duration(length_ms: int) -> dict:
    histogram.observe(length_ms)
    return {"status": "ok"}

class GaugeData(BaseModel):
    value: int

@app.put("/gauge")
def gauge_value(data: GaugeData) -> dict:
    gauge.set(data.value)
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
