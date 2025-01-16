import logging

from fastapi import FastAPI
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.metrics import set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.view import View, ExplicitBucketHistogramAggregation
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

from workshop_service import scenario, showcase

app = FastAPI(openapi_tags=[
    {
        "name": "showcase",
        "description": "APIs for the metric showcase"
    },
    {
        "name": "scenario",
        "description": "APIs for the scenarios"
    },
])

FastAPIInstrumentor.instrument_app(app)
logging.basicConfig(level=logging.INFO)

app.include_router(showcase.router, tags=["showcase"])
app.include_router(scenario.router, tags=["scenario"])

oltp_exporter = PeriodicExportingMetricReader(OTLPMetricExporter(endpoint="http://localhost:4318/v1/metrics"))
duration_view = View(
    instrument_name=showcase.DURATION_INSTRUMENT,
    aggregation=ExplicitBucketHistogramAggregation(range(0, 10000, 500)),
)
meter_provider = MeterProvider(
    metric_readers=[oltp_exporter],
    views=[duration_view]
)
set_meter_provider(meter_provider)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
