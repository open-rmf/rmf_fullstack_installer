#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))

source $SCRIPTPATH/utils.bash
export_config_vars $1

lxc info $1 &> /dev/null || create_container $RMF_FS_INSTANCE_NAME
echo "Installing mDNS"; eval_retry "lxc exec $RMF_FS_INSTANCE_NAME -- bash -c \"apt install avahi-daemon -y\"";

# SSH key generation
KEY=$HOME/.ssh/id_$RMF_FS_INSTANE_NAME
PUBKEY=$KEY.pub
AUTHORIZED_KEYS=$HOME/.ssh/authorized_keys
KNOWN_HOSTS=$HOME/.ssh/known_hosts
[ -f $PUBKEY ] || ssh-keygen -f $KEY -N '' -C "key for local lxds"
chmod 0600 $KEY $PUBKEY
grep "$(cat $PUBKEY)" $AUTHORIZED_KEYS -qs || cat $PUBKEY >> $AUTHORIZED_KEYS

touch $KNOWN_HOSTS
ssh-keygen -f "$KNOWN_HOSTS" -R "$1.local" > /dev/null 
eval_retry "lxc exec $RMF_FS_INSTANCE_NAME -- bash -c \"echo $(cat $PUBKEY) >> /root/.ssh/authorized_keys\""
eval_retry "ssh -o StrictHostKeyChecking=no root@$RMF_FS_INSTANCE_NAME.local -i $KEY echo 'SSH over mDNS is successful'"

scp -i $KEY $SCRIPTPATH/{rmf_bootstrap,rmf_setup,utils}.bash root@$RMF_FS_INSTANCE_NAME.local:~ 
scp -i $KEY $1 root@$RMF_FS_INSTANCE_NAME.local:~/config.yaml
scp -i $KEY /tmp/$RMF_FS_INSTANCE_NAME.repos root@$RMF_FS_INSTANCE_NAME.local:~/rmf.repos 

lxc exec $RMF_FS_INSTANCE_NAME -- bash -c "bash /root/rmf_bootstrap.bash /root/config.yaml"
lxc stop $RMF_FS_INSTANCE_NAME
