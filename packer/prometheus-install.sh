#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
PROMETHEUS_VERSION=2.54.1
PROMETHEUS_NODE_EXPORTER_VERSION=1.8.2
PROMETHEUS_PROCESS_EXPORTER_VERSION=0.8.5

echo '- Installing Go'
sudo apt-get -y install golang-go

echo '- Setting up Prometheus user/group'
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
sudo mkdir /etc/prometheus
sudo mkdir /mnt/prometheus
sudo chown prometheus:prometheus /mnt/prometheus

echo '- Installing Prometheus'
PROMETHEUS_PACKAGE="prometheus-${PROMETHEUS_VERSION}.linux-$(dpkg --print-architecture)"
PROMETHEUS_PACKAGE_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_PACKAGE}.tar.gz"

cd
curl -sL "$PROMETHEUS_PACKAGE_URL" | tar xvz
cd "$PROMETHEUS_PACKAGE"
sudo mv prometheus /usr/local/bin
sudo mv promtool /usr/local/bin
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo mv consoles /etc/prometheus
sudo mv console_libraries /etc/prometheus
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:8000', 'localhost:9100', 'localhost:9256']
EOF
cd
rm -rf "$PROMETHEUS_PACKAGE"
sudo chown -R prometheus:prometheus /etc/prometheus

echo '- Installing Prometheus node exporter'
PROMETHEUS_NODE_EXPORTER_PACKAGE="node_exporter-${PROMETHEUS_NODE_EXPORTER_VERSION}.linux-$(dpkg --print-architecture)"
PROMETHEUS_NODE_EXPORTER_PACKAGE_URL="https://github.com/prometheus/node_exporter/releases/download/v${PROMETHEUS_NODE_EXPORTER_VERSION}/${PROMETHEUS_NODE_EXPORTER_PACKAGE}.tar.gz"
curl -sL "$PROMETHEUS_NODE_EXPORTER_PACKAGE_URL" | tar xvz
sudo mv "$PROMETHEUS_NODE_EXPORTER_PACKAGE/node_exporter" /usr/local/bin
sudo chown prometheus:prometheus /usr/local/bin/node_exporter
rm -rf "$PROMETHEUS_NODE_EXPORTER_PACKAGE"

echo '- Installing Prometheus process exporter'
PROMETHEUS_PROCESS_EXPORTER_PACKAGE="process-exporter-${PROMETHEUS_PROCESS_EXPORTER_VERSION}.linux-$(dpkg --print-architecture)"
PROMETHEUS_PROCESS_EXPORTER_PACKAGE_URL="https://github.com/ncabatoff/process-exporter/releases/download/v${PROMETHEUS_PROCESS_EXPORTER_VERSION}/${PROMETHEUS_PROCESS_EXPORTER_PACKAGE}.tar.gz"
curl -sL "$PROMETHEUS_PROCESS_EXPORTER_PACKAGE_URL" | tar xvz
sudo mv "$PROMETHEUS_PROCESS_EXPORTER_PACKAGE/process-exporter" /usr/local/bin
sudo chown prometheus:prometheus /usr/local/bin/process-exporter
rm -rf "$PROMETHEUS_PROCESS_EXPORTER_PACKAGE"
cat <<EOF | sudo tee /etc/prometheus/process-exporter.yml
process_names:
  - comm:
    - python
EOF
sudo chown prometheus:prometheus /etc/prometheus/process-exporter.yml
cd

echo '- Installing systemd service for Prometheus components'
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /mnt/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF | sudo tee /etc/systemd/system/process-exporter.service
[Unit]
Description=Prometheus Process Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/process-exporter -config.path /etc/prometheus/process-exporter.yml

[Install]
WantedBy=multi-user.target
EOF

echo '- Enabling Prometheus service'
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl enable process-exporter
sudo systemctl enable prometheus
sudo systemctl start node_exporter
sudo systemctl start process-exporter
sudo systemctl start prometheus
