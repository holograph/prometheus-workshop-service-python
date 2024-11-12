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
sudo mkdir -p /home/student/.config/autostart
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEz4jal99UkJ8EOL/oTQQRvlRZa+gF8PXI1PeEl/+y35 lab@example.com' \
  | sudo tee /home/student/.ssh/authorized_keys
echo 'yes' | sudo tee /home/student/.config/gnome-initial-setup-done
sudo chown -R student /home/student

echo '- Setting up Conky'
sudo -ustudent desktop-file-install --dir=/home/student/.config/autostart /usr/share/applications/conky.desktop
sudo mkdir -p /home/student/.config/conky
cat <<"EOF" | sudo tee /home/student/.config/conky
-- Conky, a system monitor https://github.com/brndnmtthws/conky
--
-- This configuration file is Lua code. You can write code in here, and it will
-- execute when Conky loads. You can use it to generate your own advanced
-- configurations.
--
-- Try this (remove the `--`):
--
--   print("Loading Conky config")
--
-- For more on Lua, see:
-- https://www.lua.org/pil/contents.html

conky.config = {
    alignment = 'center',
    background = false,
    border_width = 1,
    cpu_avg_samples = 2,
    default_color = 'white',
    default_outline_color = 'white',
    default_shade_color = 'white',
    double_buffer = true,
    draw_borders = false,
    draw_graph_borders = true,
    draw_outline = false,
    draw_shades = false,
    extra_newline = false,
    font = 'DejaVu Sans Mono:size=16',
    gap_x = 60,
    gap_y = 60,
    minimum_height = 5,
    minimum_width = 5,
    no_buffers = true,
    out_to_console = false,
    out_to_ncurses = false,
    out_to_stderr = false,
    out_to_x = true,
    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_transparent = true,
    show_graph_range = false,
    show_graph_scale = false,
    stippled_borders = 0,
    update_interval = 10.0,
    uppercase = false,
    use_spacer = 'none',
    use_xft = true,
}

conky.text = [[
Welcome to your Prometheus workshop lab instance!

The two most important links you will need are:
* http://${exec curl http://169.254.169.254/latest/meta-data/public-ipv4}:8080/docs - The example service for this workshop
* http://${exec curl http://169.254.169.254/latest/meta-data/public-ipv4}:3000 - Grafana

Your instance's public IP is ${exec curl http://169.254.169.254/latest/meta-data/public-ipv4}, and provides the following SSH access via:
  ssh -i <private_key> student@${exec curl http://169.254.169.254/latest/meta-data/public-ipv4}
The private key is available from the classroom materials.
]]
EOF
sudo chown -R student /home/student/.config/conky

echo '--- Installing lab components ---'
./service-install.sh
./otel-collector-install.sh
./prometheus-install.sh
./grafana-install.sh
