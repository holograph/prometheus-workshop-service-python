#!/bin/bash -e

cloud-init status --wait

export DEBIAN_FRONTEND=noninteractive

echo '--- Installing base system ---'

echo '- Installing base components'
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y                           \
  apt-transport-https software-properties-common  \
  wget net-tools jq curl unzip

echo '- Setting up Linux desktop and lab user'
sudo apt-get install -y ubuntu-desktop gdm3
sudo useradd -g sudo -m -p $(echo "student" | openssl passwd -1 -stdin) student

echo '--- Installing lab components ---'
./service-install.sh
./prometheus-install.sh
./grafana-install.sh
