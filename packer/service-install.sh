#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo '- Installing Python'
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.12 python3.12-venv git

echo '- Setting up virtual environment'
python3.12 -mvenv venv
source ~/venv/bin/activate
pip install poetry

echo '- Setting up workshop service'
git clone https://github.com/holograph/prometheus-workshop-service-python.git
cd ~/prometheus-workshop-service-python
poetry install

echo '- Installing systemd service for workshop service'
cat <<EOF | sudo tee /etc/systemd/system/workshop-service.service
[Unit]
Description=Prometheus workshop service
Wants=network-online.target
After=network-online.target

[Service]
User=ubuntu
Group=ubuntu
Type=simple
WorkingDirectory=/home/ubuntu/prometheus-workshop-service-python
ExecStart=/home/ubuntu/venv/bin/python -m workshop_service.app

[Install]
WantedBy=multi-user.target
EOF

echo '- Enabling workshop-service'
sudo systemctl daemon-reload
sudo systemctl enable workshop-service
sudo systemctl start workshop-service
