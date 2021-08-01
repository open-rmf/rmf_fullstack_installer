#!/bin/bash

[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }

logging_export_systemd() {
cat <<EOF > /etc/systemd/system/tailon.service
[Unit]
Description=Start tailon logging

[Service]
Type=simple
ExecStart=/usr/local/bin/tailon -r /tailon/ -b 0.0.0.0:8084 -f /root/logs/*
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable tailon.service
systemctl restart tailon.service || systemctl start tailon.service
}

logging_setup() {
  DEBIAN_FRONTEND=noninteractive apt install python3-pip
  pip3 install tailon
  mkdir /root/logs
  touch /root/logs/current_launch.log
}


[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }
echo "Setting Up Logging infrastructure.."; logging_setup; logging_export_systemd;
