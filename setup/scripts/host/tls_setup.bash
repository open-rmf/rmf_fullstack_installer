#!/bin/bash
set -e

[ $EUID -eq 0 ] || { echo "Please run script as root" && exit 1; }

apt update
dpkg-query -l nginx &> /dev/null || (echo "Installing nginx" && apt install nginx -y)
which snap &> /dev/null || { echo "You will need to install snap." ; exit 1; }
snap install core; snap refresh core

dpkg-query -l certbot &> /dev/null && apt remove certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot || true

help_textbox=$(mktemp)
cat << END > $help_textbox
Your machine needs to be connected to the internet and have a registered domain name. 
Check that you can resolve the ip address of your domain name with ping.

You will require the following information:
Domain Name
Email for Association to TLS certificate
END

whiptail --textbox $help_textbox --title "TLS Setup" $LINES $COLUMNS 

certbot --nginx 

mkdir /etc/nginx/deploy
sed -i "123 a include /etc/nginx/deploy/*;" /etc/nginx/sites-enabled/default
