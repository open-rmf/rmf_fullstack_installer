#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))

source $SCRIPTPATH/utils.bash
export_config_vars $1

help_textbox=$(mktemp)
cat << END > $help_textbox
This will generate Wireguard deployment configurations in /etc/wireguard.
The host machine will be the Wireguard Server. Wireguard will use port 51820.
Once generated, this tool will not overwrite keys.
If you wish to generate new keys, delete the corresponding folder in /etc/wireguard.
END

whiptail --textbox $help_textbox --title "Setup VPN" $LINES $COLUMNS 

( which wg-quick && which resolvconf )  > /dev/null 2>&1 || ( echo "Wireguard not found. Attempting to install." && \
    apt install wireguard wireguard-tools openresolv -y )

mkdir -p /etc/wireguard/$RMF_FS_INSTANCE_NAME; cd /etc/wireguard/$RMF_FS_INSTANCE_NAME
WG_PATH=/etc/wireguard/$RMF_FS_INSTANCE_NAME

if [[ ! -d $WG_PATH/server ]]; then
    mkdir -p $WG_PATH/server; cd $WG_PATH/server; wg genkey | tee privatekey | wg pubkey > publickey
fi
server_pubkey=`cat $WG_PATH/server/publickey`

# Create wireguard templates
if [[ ! -d $WG_PATH/rmf ]]; then
    mkdir $WG_PATH/rmf; cd $WG_PATH/rmf;
    wg genkey | tee privatekey | wg pubkey > publickey
    generate_wg0_client_conf `cat privatekey` $RMF_FS_WIREGUARD_SUBNET 2 $server_pubkey $RMF_FS_SERVER_EXTERNAL_IP wg0.conf
fi
echo -e "rmf wg0.conf"; cat $WG_PATH/rmf/wg0.conf; echo -e "\n\n"

if [[ ! -d $WG_PATH/rmf-web ]]; then
    mkdir $WG_PATH/rmf-web; cd $WG_PATH/rmf-web;
    wg genkey | tee privatekey | wg pubkey > publickey
    generate_wg0_client_conf `cat privatekey` $RMF_FS_WIREGUARD_SUBNET 3 $server_pubkey $RMF_FS_SERVER_EXTERNAL_IP wg0.conf
fi
echo -e "rmf-web wg0.conf"; cat $WG_PATH/rmf-web/wg0.conf; echo -e "\n\n"

if [[ ! -d $WG_PATH/device ]]; then
    mkdir $WG_PATH/device; cd $WG_PATH/device;
    wg genkey | tee privatekey | wg pubkey > publickey
    generate_wg0_client_conf `cat privatekey` $RMF_FS_WIREGUARD_SUBNET 4 $server_pubkey $RMF_FS_SERVER_EXTERNAL_IP wg0.conf
fi
echo -e "device wg0.conf"; cat $WG_PATH/device/wg0.conf; echo -e "\n\n"

cd $WG_PATH/server
cat << END > $WG_PATH/server/wg0.conf
[Interface]
Address = $RMF_FS_WIREGUARD_SUBNET.1/24
ListenPort = 51820
PrivateKey = `cat privatekey`

[Peer]
PublicKey = `cat $WG_PATH/rmf/publickey`
AllowedIPs = $RMF_FS_WIREGUARD_SUBNET.2/32

[Peer]
PublicKey = `cat $WG_PATH/rmf-web/publickey`
AllowedIPs = $RMF_FS_WIREGUARD_SUBNET.3/32

[Peer]
PublicKey = `cat $WG_PATH/device/publickey`
AllowedIPs = $RMF_FS_WIREGUARD_SUBNET.4/32
END

echo -e "server wg0.conf"; cat $WG_PATH/server/wg0.conf; echo -e "\n\n"
echo "Wireguard config generation complete."
