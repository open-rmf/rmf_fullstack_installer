#!/bin/bash
set -e

script_path=$(dirname $(realpath "$0"))

get_ingress_ip() {
  su -l web -c '/home/web/rmf-web/example-deployment/.bin/minikube ip'
}

install_docker() {
    apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release -y

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io -y
}

install_docker
apt install firefox nginx sudo -y

useradd -m -G sudo,docker web -s /bin/bash || true

# Set up rmf-web
mkdir -p /home/web/rmf-web
cp -r $(find /opt/rmf -name "rmf-web")/* /home/web/rmf-web
cp /root/deploy_web_setup.bash /home/web

chown -R web /home/web/rmf-web
chown web /home/web/.bashrc /home/web/deploy_web_setup.bash
chgrp web /home/web/.bashrc /home/web/deploy_web_setup.bash

su -l web -c "cd /home/web; bash /home/web/deploy_web_setup.bash $1" 

# Add /etc/hosts to point to ingress
sed -i "s/.*# MINIKUBE//g" /etc/hosts
sed -i '$d' /etc/hosts
echo "`get_ingress_ip`    $1 # MINIKUBE" >> /etc/hosts

su -l web -c "source /home/web/.nvm/nvm.sh; cd /home/web/rmf-web/example-deployment; bash deploy.sh --rmf-ws /opt/rmf --rmf-web-ws /home/web/rmf-web" 

cat <<EOF  > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
        worker_connections 768;
        # multi_accept on;
}
stream {
  upstream web_server {
    server $1:443; # Need entry in /etc/hosts
  }
  upstream web_insecure_server {
    server $1:80; # Need entry in /etc/hosts
  }
  server {
    listen 443;
    proxy_pass web_server;
  }
  server {
    listen 80;
    proxy_pass web_insecure_server;
  }
}
EOF
