#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.12 python3.12-venv git

python3.12 -mvenv venv
source ~/venv/bin/activate
pip install poetry

git clone https://github.com/holograph/prometheus-workshop-service-python.git
cd ~/prometheus-workshop-service-python
poetry install


