#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
OTEL_COLLECTOR_VERSION=0.113.0
OTEL_COLLECTOR_PACKAGE="otelcol_${OTEL_COLLECTOR_VERSION}_linux_$(dpkg --print-architecture).deb"

wget "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_COLLECTOR_VERSION}/${OTEL_COLLECTOR_PACKAGE}"
sudo dpkg -i "${OTEL_COLLECTOR_PACKAGE}"
rm "${OTEL_COLLECTOR_PACKAGE}"

cat <<"EOF" | sudo tee /etc/otelcol/config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
exporters:
  prometheus:
    endpoint: "0.0.0.0:8000"
    resource_to_telemetry_conversion:
      enabled: true
service:
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [prometheus]
EOF
sudo systemctl restart otelcol
