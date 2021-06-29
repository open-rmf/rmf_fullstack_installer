#!/bin/bash
novnc_setup() {
  wget https://github.com/novnc/noVNC/archive/refs/tags/v1.2.0.tar.gz -O /tmp/novnc.tar.gz
  mkdir /usr/src/noVNC || true
  tar -xzvf /tmp/novnc.tar.gz -C /usr/src/noVNC --strip-components 1
}

novnc_export_systemd() {
  touch /etc/systemd/system/novnc@.service
  cat <<\EOF > /etc/systemd/system/novnc@.service
[Unit]
Description=Launch noVNC on startup
[Service]
Type=simple
ExecStart=/usr/src/noVNC/utils/launch.sh --vnc localhost:590%i --listen 608%i
ExecStop=vncserver kill :%i
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload 
}

[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }
echo "Downloading noVNC.."; novnc_setup
echo "Exporting noVNC Systemd config.."; novnc_export_systemd
