#!/bin/bash

env > /dev/null 2>&1

SCRIPTPATH=$(dirname $(realpath "$0"))
source $SCRIPTPATH/utils.bash
export_config_vars $1
RMF_WEB_INSTANCE_NAME=$RMF_FS_INSTANCE_NAME-web


WG_SUBNET=$(whiptail \
    --nocancel \
    --inputbox "Enter your Wireguard Subnet prefix ( Omit the last byte ). Only supports /24 subnets." \
    --title "Deploy Configs" \
    $LINES $COLUMNS 10.11.12 \
    3>&1 1>&2 2>&3)

lxc info $RMF_FS_INSTANCE_NAME &> /dev/null || { echo "Please Create $RMF container for $RMF_FS_INSTANCE_NAME first."; exit 1; }
lxc info $RMF_WEB_INSTANCE_NAME &> /dev/null || { echo "Please Create rmf-web container for $RMF_FS_INSTANCE_NAME first."; exit 1; }

echo "Configuring /etc/hosts on host machine" 
lxc restart $RMF_FS_INSTANCE_NAME > /dev/null 2>&1 || lxc start $RMF_FS_INSTANCE_NAME
lxc restart $RMF_WEB_INSTANCE_NAME > /dev/null 2>&1 || lxc start $RMF_WEB_INSTANCE_NAME

echo "Retrieving ip address of $RMF_FS_INSTANCE_NAME"
rmf_ip=`get_lxc_ip $RMF_FS_INSTANCE_NAME eth0`
sed -i "/$rmf_ip.*/d" /etc/hosts
echo "$rmf_ip    $RMF_FS_INSTANCE_NAME.local" >> /etc/hosts

echo "Retrieving ip address of $RMF_WEB_INSTANCE_NAME"
web_ip=`get_lxc_ip $RMF_WEB_INSTANCE_NAME eth0`
sed -i "/$web_ip.*/d" /etc/hosts
echo "$web_ip    $RMF_WEB_INSTANCE_NAME.local" >> /etc/hosts

echo "Checking config files are present."
[[ -f /etc/wireguard/$RMF_FS_INSTANCE_NAME/rmf/wg0.conf ]] || { echo "rmf wg0.conf not missing."; exit 1; }
[[ -f /etc/wireguard/$RMF_FS_INSTANCE_NAME/rmf-web/wg0.conf ]] || { echo "rmf-web wg0.conf not missing."; exit 1; }
[[ -f /etc/wireguard/$RMF_FS_INSTANCE_NAME/device/wg0.conf ]] || { echo "device wg0.conf not missing."; exit 1; }
[[ -f /etc/wireguard/$RMF_FS_INSTANCE_NAME/server/wg0.conf ]] || { echo "server wg0.conf not missing."; exit 1; }
echo "Success."

echo "Deploying Wireguard Configs"
lxc exec $RMF_FS_INSTANCE_NAME -- apt install wireguard wireguard-tools openresolv -y
lxc file push /etc/wireguard/$RMF_FS_INSTANCE_NAME/rmf/wg0.conf $RMF_FS_INSTANCE_NAME/etc/wireguard/

lxc exec $RMF_WEB_INSTANCE_NAME -- apt install wireguard wireguard-tools openresolv -y
lxc file push /etc/wireguard/$RMF_FS_INSTANCE_NAME/rmf-web/wg0.conf $RMF_WEB_INSTANCE_NAME/etc/wireguard/

cp /etc/wireguard/$RMF_FS_INSTANCE_NAME/server/wg0.conf /etc/wireguard
restart_wg
lxc exec $RMF_FS_INSTANCE_NAME -- wg-quick down wg0
lxc exec $RMF_WEB_INSTANCE_NAME -- wg-quick down wg0

lxc exec $RMF_FS_INSTANCE_NAME -- wg-quick up wg0
lxc exec $RMF_WEB_INSTANCE_NAME -- wg-quick up wg0

echo "Deploying nginx"
which nginx > /dev/null 2>&1 || sudo apt install nginx -y
mkdir /etc/nginx/deploy &> /dev/null || true
touch /etc/nginx/deploy/web_proxy

echo """
location /auth {
    proxy_pass https://$RMF_WEB_INSTANCE_NAME.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}
location /dashboard {
    proxy_pass https://$RMF_WEB_INSTANCE_NAME.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}

location /reporting {
    proxy_pass https://$RMF_WEB_INSTANCE_NAME.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}

location /logserver/api/v1 {
    proxy_pass https://$RMF_WEB_INSTANCE_NAME.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}

location /rmf/api/v1/socket.io {
    proxy_pass https://$RMF_WEB_INSTANCE_NAME.local;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}

location /rmf/api/v1 {
    proxy_pass https://$RMF_WEB_INSTANCE_NAME.local;
    proxy_set_header Host            \$host;
    proxy_set_header X-Forwarded-For \$remote_addr;
}

location /trajectory {
    rewrite /trajectory /   break;
    proxy_pass http://$RMF_WEB_INSTANCE_NAME.local:$RMF_FS_WEBSOCKET_PORT;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection upgrade;
    proxy_read_timeout 86400;
    proxy_set_header Host            \$host:\$server_port;
    proxy_set_header X-Forwarded-For \$remote_addr;
}""" > /etc/nginx/deploy/web_proxy

systemctl restart nginx
nginx -s reload

echo "Copying configuration files"
CONFIGPATH=$SCRIPTPATH/../../config
sed "s/10.11.12/$WG_SUBNET/g" $CONFIGPATH/cyclonedds.xml  > /tmp/cyclonedds.xml
lxc file push /tmp/cyclonedds.xml $RMF_FS_INSTANCE_NAME/root/
lxc file push /tmp/cyclonedds.xml $RMF_WEB_INSTANCE_NAME/root/

sed "s/10.11.12/$WG_SUBNET/g" $CONFIGPATH/fastdds.xml  > /tmp/fastdds.xml
lxc file push /tmp/fastdds.xml $RMF_FS_INSTANCE_NAME/root/
lxc file push /tmp/fastdds.xml $RMF_WEB_INSTANCE_NAME/root/

cp $CONFIGPATH/.bashrc /tmp/.bashrc
echo "source /opt/ros/$RMF_FS_ROS_VERSION/setup.bash" >> /tmp/.bashrc
echo 'source /opt/rmf/install/setup.bash' >> /tmp/.bashrc
echo "export RMW_IMPLEMENTATION=$RMF_FS_RMW_IMPLEMENTATION" >> /tmp/.bashrc
echo "export ROS_DOMAIN_ID=$RMF_FS_ROS_DOMAIN_ID" >> /tmp/.bashrc
echo 'export FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds.xml' >> /tmp/.bashrc
grep -qxF 'export CYCLONEDDS_URI=file:///root/cyclonedds.xml' /tmp/.bashrc || echo 'export CYCLONEDDS_URI=file:///root/cyclonedds.xml' >> /tmp/.bashrc
lxc file push /tmp/.bashrc $RMF_FS_INSTANCE_NAME/root/
lxc file push /tmp/.bashrc $RMF_WEB_INSTANCE_NAME/root/

cp $CONFIGPATH/.profile /tmp/.profile
echo "source /opt/ros/$RMF_FS_ROS_VERSION/setup.bash" >> /tmp/.profile
echo 'source /opt/rmf/install/setup.bash' >> /tmp/.profile
echo "export RMW_IMPLEMENTATION=$RMF_FS_RMW_IMPLEMENTATION" >> /tmp/.profile
echo "export ROS_DOMAIN_ID=$RMF_FS_ROS_DOMAIN_ID" >> /tmp/.profile
echo 'export FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds.xml' >> /tmp/.profile
grep -qxF 'export CYCLONEDDS_URI=file:///root/cyclonedds.xml' /tmp/.profile || echo 'export CYCLONEDDS_URI=file:///root/cyclonedds.xml' >> /tmp/.profile
lxc file push /tmp/.profile $RMF_FS_INSTANCE_NAME/root/
lxc file push /tmp/.profile $RMF_WEB_INSTANCE_NAME/root/

# Make sure ip forwarding is enabled  
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT
