#!/bin/bash
set -e

SCRIPTPATH=$(dirname $(realpath "$0"))
source $SCRIPTPATH/utils.bash

install_docker

useradd -m -G sudo,docker web -s /bin/bash || true

# Set up rmf-web
mkdir -p /home/web/rmf-web
cp -r $(find /opt/rmf -name "rmf-web")/* /home/web/rmf-web
cp /root/deploy_web_setup.bash /home/web

chown -R web /home/web/rmf-web
chown web /home/web/.bashrc /home/web/deploy_web_setup.bash
chgrp web /home/web/.bashrc /home/web/deploy_web_setup.bash

curl https://get.k3s.io | INSTALL_K3S_EXEC="server --no-deploy traefik --docker --write-kubeconfig-mode 644" sh

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml

kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

# Add /etc/hosts
echo "Getting kubernetes ingress_ip. Waiting for it to come online.."
ip=`get_ingress_ip`
sed -i "/$ip .*/d" /etc/hosts
echo "$ip    $1" >> /etc/hosts
