#!/bin/bash
set -e

curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 14
nvm use 14
pip3 install pipenv

cd /home/web/rmf-web/example-deployment
grep -rl 'example.com' . | xargs sed -i "s/example.com/$1/g" || true 
grep -rl 'ws://localhost' . | xargs sed -i "s/ws:\/\/localhost:8006/wss:\/\/$1\/trajectory/g" || true

rmf_ws=/opt/rmf
rmf_web_ws=/home/web/rmf-web

cd /home/web/rmf-web/example-deployment/

echo 'building base keycloak image...'
docker build -t rmf-web/keycloak -f docker/keycloak/keycloak.dockerfile docker/keycloak/
echo 'publishing keycloak image...'
docker save rmf-web/keycloak -o keycloak.zip
docker load -i keycloak.zip
echo 'deploying keycloak...'

kubectl apply -f k8s/keycloak.yaml
echo 'waiting for keycloak to be ready...'
kubectl wait --for=condition=available deployment/keycloak --timeout=2m

echo 'creating jwt configmap...'
function try() {
  "$@" || (sleep 1 && "$@") || (sleep 5 && "$@")
}


# sometimes keycloak reports that it is ready before it can actually serve requests
try node keycloak-tools/bootstrap-keycloak.js
try node keycloak-tools/get-cert.js > keycloak.pem
openssl x509 -in keycloak.pem -pubkey -noout -out jwt-pub-key.pub
kubectl create configmap jwt-pub-key --from-file=jwt-pub-key.pub -o=yaml --dry-run=client | kubectl apply -f -

echo 'deploying Minio...'
kubectl apply -f k8s/minio.yaml

echo 'building base rmf image...'
docker build -t rmf-web/builder -f docker/builder.dockerfile $rmf_ws/src

echo 'building rmf-server image...'
docker build -t rmf-web/rmf-server -f docker/rmf-server.dockerfile $rmf_web_ws
echo 'publishing rmf-server image...'
docker save rmf-web/rmf-server -o rmf-server.zip 
docker load -i rmf-server.zip 

echo 'creating rmf-server configmap...'
kubectl create configmap rmf-server-config --from-file=rmf_server_config.py -o=yaml --dry-run=client | kubectl apply -f -
echo 'deploying rmf-server...'
kubectl apply -f k8s/rmf-server.yaml

echo 'building dashboard image...'
docker build -t rmf-web/dashboard -f docker/dashboard.dockerfile $rmf_web_ws
echo 'publishing dashboard image...'
docker save rmf-web/dashboard -o dashboard.zip
docker load -i dashboard.zip

echo 'deploying dashboard...'
kubectl apply -f k8s/dashboard.yaml


echo 'building reporting-server image...'
docker build -t rmf-web/reporting-server -f docker/reporting-server.dockerfile $rmf_web_ws
echo 'publishing reporting-server image...'
docker save rmf-web/reporting-server --o reporting-server.zip
docker load -i reporting-server.zip

echo 'creating reporting-server configmap...'
kubectl create configmap reporting-server-config --from-file=reporting_server_config.py -o=yaml --dry-run=client | kubectl apply -f -
echo 'deploying reporting-server...'
kubectl apply -f k8s/reporting-server.yaml


echo 'building reporting image...'
docker build -t rmf-web/reporting -f docker/reporting.dockerfile $rmf_web_ws
echo 'publishing reporting image...'
docker save rmf-web/reporting -o reporting.zip
docker load -i reporting.zip

echo 'deploying reporting-server...'
kubectl apply -f k8s/reporting.yaml

echo 'Applying FluentD configmap ...'
kubectl apply -f k8s/fluentd-configmap.yaml
echo 'deploying FluentD daemonset...'
kubectl apply -f k8s/fluentd.yaml


