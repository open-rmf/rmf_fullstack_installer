#!/bin/bash
set -e

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 14
nvm use 14
pip3 install pipenv

cd /home/web/rmf-web/example-deployment
grep -rl 'example.com' . | xargs sed -i "s/example.com/$1/g" || true 
grep -rl 'ws://localhost' . | xargs sed -i "s/ws:\/\/localhost:8006/wss:\/\/$1\/trajectory/g" || true
grep -qxF 'alias kubectl="/home/web/rmf-web/example-deployment/.bin/minikube kubectl --"' /home/web/.bashrc || echo 'alias kubectl="/home/web/rmf-web/example-deployment/.bin/minikube kubectl --"' >> /home/web/.bashrc

cd /home/web/rmf-web/example-deployment
mkdir -p .bin
curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o .bin/minikube
chmod +x .bin/minikube

.bin/minikube start --cpus=$(nproc) --driver=docker --addons ingress
# ingress doesn't always come up immediately, so this patch will remove the check
.bin/minikube kubectl -- delete -A ValidatingWebhookConfiguration ingress-nginx-admission
