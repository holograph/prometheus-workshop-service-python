#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
PROMETHEUS_VERSION=2.54.1

echo '--- Initial setup ---'

echo '- Updating and installing packages'
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install jq golang-go curl unzip

echo '- Setting up Prometheus user/group'
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
sudo mkdir /etc/prometheus
sudo mkdir /mnt/prometheus

echo '--- Installing Prometheus ---'
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
      - targets: ['localhost:8080']
EOF
cd
rm -rf "$PROMETHEUS_PACKAGE"
sudo chown -R prometheus:prometheus /etc/prometheus

echo '- Installing systemd service for Prometheus'
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

echo '--- Enabling services ---'
sudo systemctl daemon-reload
sudo systemctl enable prometheus
