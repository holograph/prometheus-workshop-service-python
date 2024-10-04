#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

sudo systemctl daemon-reload
sudo systemctl start grafana-server

# Enable anonymous login
cat <<EOF | sudo patch /etc/grafana/grafana.ini
570c570
< ;disable_login_form = false
---
> disable_login_form = false
615c615
< ;enabled = false
---
> enabled = true
621c621
< ;org_role = Viewer
---
> org_role = Admin
EOF

sudo systemctl restart grafana-server

# Set up Prometheus data source
curl -XPOST -H 'Content-type: application/json'       \
  -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://localhost:9090",
        "access": "proxy",
        "isDefault": true
      }'                                              \
  'http://localhost:3000/api/datasources'

