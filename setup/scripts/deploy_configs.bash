#!/bin/bash

env > /dev/null 2>&1

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# $1: RMF_FS_INSTANCE_NAME
# $2: RMF_FS_URL
# $3: RMF_FS_ROS_VERSION
# $4: RMF_FS_ROS_DOMAIN_ID
# $5: RMF_FS_RMW_IMPLEMENTATION
# $6: RMF_FS_WEBSOCKET_PORT

restart_wg(){
    wg-quick down wg0 > /dev/null 2>&1 || true
    systemctl restart wg-quick@wg0.service
    systemctl enable wg-quick@wg0.service
}

WG_SUBNET=$(whiptail \
    --nocancel \
    --inputbox "Enter your Wireguard Subnet prefix ( Omit the last byte ). Only supports /24 subnets." \
    --title "Deploy Configs" \
    $LINES $COLUMNS 10.11.12 \
    3>&1 1>&2 2>&3)

lxc info $1 &> /dev/null || (echo "Please Create RMF container for $1 first." && exit 1)
lxc info $1-web &> /dev/null || (echo "Please Create rmf-web container for $1 first." && exit 1)

echo "Checking config files are present."
[[ -f /etc/wireguard/$1/rmf/wg0.conf ]] || (echo "rmf wg0.conf not missing." && exit 1)
[[ -f /etc/wireguard/$1/rmf-web/wg0.conf ]] || (echo "rmf-web wg0.conf not missing." && exit 1)
[[ -f /etc/wireguard/$1/device/wg0.conf ]] || (echo "device wg0.conf not missing." && exit 1)
[[ -f /etc/wireguard/$1/server/wg0.conf ]] || (echo "server wg0.conf not missing." && exit 1)
echo "Success."

echo "Deploying Wireguard Configs"
lxc exec $1 -- apt install wireguard wireguard-tools openresolv -y
lxc file push /etc/wireguard/$1/rmf/wg0.conf $1/etc/wireguard/

lxc exec $1-web -- apt install wireguard wireguard-tools openresolv -y
lxc file push /etc/wireguard/$1/rmf-web/wg0.conf $1-web/etc/wireguard/

cp /etc/wireguard/$1/server/wg0.conf /etc/wireguard
restart_wg
lxc exec $1 -- wg-quick down wg0
lxc exec $1-web -- wg-quick down wg0

lxc exec $1 -- wg-quick up wg0
lxc exec $1-web -- wg-quick up wg0

echo "Deploying nginx"
which nginx > /dev/null 2>&1 || sudo apt install nginx -y
mkdir /etc/nginx/deploy &> /dev/null || true
touch /etc/nginx/deploy/web_proxy

echo """
location /auth {
    proxy_pass https://$1-web.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}
location /dashboard {
    proxy_pass https://$1-web.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}
location /rmf/api/v1/socket.io {
    proxy_pass https://$1-web.local;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}
location /rmf/api/v1 {
    proxy_pass https://$1-web.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}
location /trajectory {
    rewrite /trajectory /   break;
    proxy_pass http://$1-web.local:$6;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection upgrade;
    proxy_read_timeout 86400;
    proxy_set_header Host            \$host:\$server_port;
    proxy_set_header X-Forwarded-For \$remote_addr;
}""" > /etc/nginx/deploy/web_proxy

systemctl restart nginx
nginx -s reload
lxc exec $1-web -- bash -c "systemctl restart nginx"

echo "Copying configuration files"
sed "s/10.11.12/$WG_SUBNET/g" $SCRIPTPATH/../config/cyclonedds.xml  > /tmp/cyclonedds.xml
lxc file push /tmp/cyclonedds.xml $1/root/
lxc file push /tmp/cyclonedds.xml $1-web/root/

sed "s/10.11.12/$WG_SUBNET/g" $SCRIPTPATH/../config/fastdds.xml  > /tmp/fastdds.xml
lxc file push /tmp/fastdds.xml $1-web/root/

cp $SCRIPTPATH/../config/.bashrc /tmp/.bashrc
grep -qxF "source /opt/ros/$3/setup.bash" /tmp/.bashrc || echo "source /opt/ros/$3/setup.bash" >> /tmp/.bashrc
grep -qxF 'source /opt/rmf/install/setup.bash' /tmp/.bashrc || echo 'source /opt/rmf/install/setup.bash' >> /tmp/.bashrc
grep -qxF "export RMW_IMPLEMENTATION=$5" /tmp/.bashrc || echo "export RMW_IMPLEMENTATION=$5" >> /tmp/.bashrc
grep -qxF "export ROS_DOMAIN_ID=$4" /tmp/.bashrc || echo "export ROS_DOMAIN_ID=$4" >> /tmp/.bashrc
grep -qxF 'export FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds.xml' /tmp/.bashrc || echo 'export FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds.xml' >> /tmp/.bashrc
grep -qxF 'export CYCLONEDDS_URI=file:///root/cyclonedds.xml' /tmp/.bashrc || echo 'export CYCLONEDDS_URI=file:///root/cyclonedds.xml' >> /tmp/.bashrc
lxc file push /tmp/.bashrc $1/root/
lxc file push /tmp/.bashrc $1-web/root/
