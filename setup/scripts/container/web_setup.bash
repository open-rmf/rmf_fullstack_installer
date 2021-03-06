#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))
source $SCRIPTPATH/utils.bash

cd /opt/rmf
cp /root/rmf.repos /opt/rmf/rmf.repos
vcs import src < rmf.repos
cd src
find . -type d -name .git -exec sh -c "cd \"{}\"/../ && pwd && git pull -f" \;

install_docker

useradd -m -G sudo,docker web -s /bin/bash || true

# Set up rmf-web
mkdir -p /home/web/rmf-web
cp -r $(find /opt/rmf -name "rmf-web")/* /home/web/rmf-web
cp /root/deploy_web_setup.bash /home/web
cp /root/{cyclonedds,fastdds}.xml /home/web

chown -R web /home/web/rmf-web
chown web /home/web/.bashrc /home/web/deploy_web_setup.bash /home/web/{cyclonedds,fastdds}.xml
chgrp web /home/web/.bashrc /home/web/deploy_web_setup.bash /home/web/{cyclonedds,fastdds}.xml

curl https://get.k3s.io | INSTALL_K3S_EXEC="server --no-deploy traefik --docker --write-kubeconfig-mode 644" sh


kubectl apply -f /home/web/rmf-web/example-deployment/k8s/ingress.yaml || kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

# Add /etc/hosts
echo "Getting kubernetes ingress_ip. Waiting for it to come online.."
ip=`get_ingress_ip`
sed -i "/$ip .*/d" /etc/hosts
echo "$ip    $1" >> /etc/hosts
