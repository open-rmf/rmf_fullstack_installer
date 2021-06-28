#!/bin/bash

help_textbox=$(mktemp)
cat << END > $help_textbox
This will generate Wireguard deployment configurations in /etc/wireguard.
The host machine will be the Wireguard Server. Wireguard will use port 51820.
Once generated, this tool will not overwrite keys.
If you wish to generate new keys, delete the corresponding folder in /etc/wireguard.
END

WG_SUBNET=$(whiptail \
    --nocancel \
    --inputbox "Enter your Wireguard Subnet prefix ( Omit the last byte ). Only supports /24 subnets." \
    --title "Setup VPN" \
    $LINES $COLUMNS 10.11.12 \
    3>&1 1>&2 2>&3)

WG_EXT_IP=$(whiptail \
    --nocancel \
    --inputbox "Enter the external IP of your wireguard server ( this host machine )." \
    --title "Setup VPN" \
    $LINES $COLUMNS 192.168.0.1 \
    3>&1 1>&2 2>&3)

( which wg-quick && which resolvconf )  > /dev/null 2>&1 || ( echo "Wireguard not found. Attempting to install." && \
    apt install wireguard wireguard-tools openresolv -y )

mkdir -p /etc/wireguard/$1; cd /etc/wireguard/$1
WG_PATH=/etc/wireguard/$1

generate_wg0_client_conf() {
# $1 - privatekey
# $2 - subnet
# $3 - device id
# $4 - publickey
# $5 - server external ip
# $6 - conf file path
cat << END > $6
[Interface]
PrivateKey = $1 
Address = $2.$3/32
DNS = 8.8.8.8
PostUp = ping $2.1 -c 1

[Peer]
PublicKey = $4 
Endpoint = $5:51820
AllowedIPs = $2.0/24
END
}

# Create wireguard templates
if [[ ! -d $WG_PATH/rmf ]]; then
    mkdir $WG_PATH/rmf; cd $WG_PATH/rmf;
    wg genkey | tee privatekey | wg pubkey > publickey
    generate_wg0_client_conf `cat privatekey` $WG_SUBNET 2 `cat publickey` $WG_EXT_IP wg0.conf
fi
echo -e "rmf wg0.conf"; cat $WG_PATH/rmf/wg0.conf; echo -e "\n\n"

if [[ ! -d $WG_PATH/rmf-web ]]; then
    mkdir $WG_PATH/rmf-web; cd $WG_PATH/rmf-web;
    wg genkey | tee privatekey | wg pubkey > publickey
    generate_wg0_client_conf `cat privatekey` $WG_SUBNET 3 `cat publickey` $WG_EXT_IP wg0.conf
fi
echo -e "rmf-web wg0.conf"; cat $WG_PATH/rmf-web/wg0.conf; echo -e "\n\n"

if [[ ! -d $WG_PATH/device ]]; then
    mkdir $WG_PATH/device; cd $WG_PATH/device;
    wg genkey | tee privatekey | wg pubkey > publickey
    generate_wg0_client_conf `cat privatekey` $WG_SUBNET 4 `cat publickey` $WG_EXT_IP wg0.conf
fi
echo -e "device wg0.conf"; cat $WG_PATH/device/wg0.conf; echo -e "\n\n"

if [[ ! -d $WG_PATH/server ]]; then
    mkdir $WG_PATH/server; cd $WG_PATH/server;
    wg genkey | tee privatekey | wg pubkey > publickey
    cat << END > $WG_PATH/server/wg0.conf
[Interface]
Address = $WG_SUBNET.1/24
ListenPort = 51820
PrivateKey = `cat privatekey`

[Peer]
PublicKey = `cat $WG_PATH/rmf/publickey`
AllowedIPs = $WG_SUBNET.2/32

[Peer]
PublicKey = `cat $WG_PATH/rmf-web/publickey`
AllowedIPs = $WG_SUBNET.3/32

[Peer]
PublicKey = `cat $WG_PATH/device/publickey`
AllowedIPs = $WG_SUBNET.4/32
END
fi

echo -e "server wg0.conf"; cat $WG_PATH/server/wg0.conf; echo -e "\n\n"
echo "Wireguard config generation complete."
