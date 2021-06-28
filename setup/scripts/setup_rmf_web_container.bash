#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))

lxc info $1 &> /dev/null || echo "Please Create RMF container first."
lxc info $1-web &> /dev/null || (echo "Copying container $1 to $1-web, this might take a while"; lxc copy $1 $1-web)
lxc profile assign $1-web default,nat,minikube
lxc start $1-web

eval_retry () {
while ! eval $1;
do
  echo "Retrying Command.."
  sleep 2
done
}

# SSH key generation
KEY=$HOME/.ssh/id_$1
PUBKEY=$KEY.pub
AUTHORIZED_KEYS=$HOME/.ssh/authorized_keys
KNOWN_HOSTS=$HOME/.ssh/known_hosts
[ -f $PUBKEY ] || ssh-keygen -f $KEY -N '' -C "key for local lxds"
chmod 0600 $KEY $PUBKEY
grep "$(cat $PUBKEY)" $AUTHORIZED_KEYS -qs || cat $PUBKEY >> $AUTHORIZED_KEYS

touch $KNOWN_HOSTS
ssh-keygen -f "$KNOWN_HOSTS" -R "$1-web.local"
eval_retry "lxc exec $1-web -- bash -c \"echo $(cat $PUBKEY) >> /root/.ssh/authorized_keys\""
eval_retry "ssh -o StrictHostKeyChecking=no root@$1-web.local -i $KEY echo 'SSH over mDNS is successful'"

scp -i $KEY $SCRIPTPATH/web_setup.bash root@$1-web.local:~ 
scp -i $KEY $SCRIPTPATH/deploy_web_setup.bash root@$1-web.local:~ 

lxc exec $1-web -- bash -c "bash /root/web_setup.bash $2"
