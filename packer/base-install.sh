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
  wget net-tools jq curl zip unzip

echo '- Setting up MOTD'
cat <<"EOF_OUT" | sudo tee /usr/local/sbin/generate-motd.sh
#!/bin/bash

public_ip="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
cat <<EOF | sudo tee /etc/motd
Welcome to your Prometheus workshop lab instance!

The two most important links you will need are:
* http://${public_ip}:8080/docs - The example service for this workshop
* http://${public_ip}:3000 - Grafana

Your instance's public IP is ${public_ip}, and provides the following SSH access via:
  ssh -i <private_key> student@${public_ip}
The private key is available from the classroom materials.

Running scenarios with the example service:
* curl "${service_url}/scenario/health"
  Shows the status of the currently running scenario (if any), as well as the names of available scenarios
* curl -XPOST "${service_url}/scenario/<name>?action=<action>"
  Performs an action on a particular scenario. Available actions include "start" and "stop" (no quotes)

Additionally, if desired, you can also access Prometheus directly via: http://${public_ip}:9090

Good luck!

EOF
EOF_OUT

cat <<EOF | sudo tee /etc/systemd/system/generate-motd.service
[Unit]
Description=Generate MOTD for lab setup

[Service]
ExecStart=/usr/local/sbin/generate-motd.sh

[Install]
WantedBy=multi-user.target
EOF

sudo chmod u+x /usr/local/sbin/generate-motd.sh
sudo systemctl enable generate-motd.service

echo '- Setting up Linux desktop and lab user'
sudo apt-get install -y ubuntu-desktop-minimal
sudo useradd -g sudo -m -s /bin/bash -p $(echo "student" | openssl passwd -1 -stdin) student
sudo mkdir -p /home/student/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEz4jal99UkJ8EOL/oTQQRvlRZa+gF8PXI1PeEl/+y35 lab@example.com' \
  | sudo tee /home/student/.ssh/authorized_keys
sudo chown -R student /home/student/.ssh

echo '--- Installing lab components ---'
./service-install.sh
./otel-collector-install.sh
./prometheus-install.sh
./grafana-install.sh
