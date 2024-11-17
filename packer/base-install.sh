#!/bin/bash -e

cloud-init status --wait

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

echo '--- Installing base system ---'

echo '- Installing base components'
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y                           \
  apt-transport-https software-properties-common  \
  wget net-tools jq curl zip unzip conky

echo '- Setting up Linux desktop and lab user'
sudo apt-get install -y ubuntu-desktop-minimal
sudo useradd -g sudo -m -s /bin/bash -p $(echo "student" | openssl passwd -1 -stdin) student
sudo mkdir -p /home/student/.ssh
sudo mkdir -p /home/student/.config/autostart
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEz4jal99UkJ8EOL/oTQQRvlRZa+gF8PXI1PeEl/+y35 lab@example.com' \
  | sudo tee /home/student/.ssh/authorized_keys
echo 'yes' | sudo tee /home/student/.config/gnome-initial-setup-done
sudo chown -R student /home/student
./conky-install.sh

echo '- Disabling autoupdate dialogs'
cat <<"EOF" | sudo tee /etc/apt/apt.conf.d/20auto-upgrade
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
sudo sed -i 's/Prompt=lts/Prompt=never/' /etc/update-manager/release-upgrades

echo '--- Installing lab components ---'
./service-install.sh
./otel-collector-install.sh
./prometheus-install.sh
./grafana-install.sh
