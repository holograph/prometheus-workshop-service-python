import logging

from fastapi import FastAPI
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.metrics import set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

import workshop_service.scenario
import workshop_service.showcase

app = FastAPI()
FastAPIInstrumentor.instrument_app(app)
logging.basicConfig(level=logging.INFO)

app.include_router(workshop_service.showcase.router)
app.include_router(workshop_service.scenario.router)

set_meter_provider(
    MeterProvider(
        metric_readers=[
            PeriodicExportingMetricReader(OTLPMetricExporter(endpoint="http://localhost:4318/v1/metrics"))
        ]
    )
)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
