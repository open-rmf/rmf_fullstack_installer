#!bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))

source $SCRIPTPATH/utils.bash
export_config_vars $1

lxc info $RMF_FS_INSTANCE_NAME &> /dev/null || echo "Please Create RMF container first."

RMF_WEB_INSTANCE_NAME=$RMF_FS_INSTANCE_NAME-web

lxc stop $RMF_FS_INSTANCE_NAME > /dev/null 2>&1
lxc info $RMF_WEB_INSTANCE_NAME &> /dev/null || (echo "Copying container $RMF_FS_INSTANCE_NAME to $RMF_WEB_INSTANCE_NAME, this might take a while"; lxc copy $RMF_FS_INSTANCE_NAME $RMF_WEB_INSTANCE_NAME)
lxc profile assign $RMF_WEB_INSTANCE_NAME default,nat,kubernetes
lxc start $RMF_WEB_INSTANCE_NAME

# SSH key generation
KEY=$HOME/.ssh/id_$RMF_FS_INSTANCE_NAME
PUBKEY=$KEY.pub
AUTHORIZED_KEYS=$HOME/.ssh/authorized_keys
KNOWN_HOSTS=$HOME/.ssh/known_hosts
[ -f $PUBKEY ] || ssh-keygen -f $KEY -N '' -C "key for local lxds"
chmod 0600 $KEY $PUBKEY
grep "$(cat $PUBKEY)" $AUTHORIZED_KEYS -qs || cat $PUBKEY >> $AUTHORIZED_KEYS

touch $KNOWN_HOSTS
ssh-keygen -f "$KNOWN_HOSTS" -R "$RMF_WEB_INSTANCE_NAME.local"
eval_retry "lxc exec $RMF_WEB_INSTANCE_NAME -- bash -c \"echo $(cat $PUBKEY) >> /root/.ssh/authorized_keys\""
eval_retry "ssh -o StrictHostKeyChecking=no root@$RMF_WEB_INSTANCE_NAME.local -i $KEY echo 'SSH over mDNS is successful'"

scp -i $KEY $SCRIPTPATH/{web_bootstrap,web_setup,deploy_web_setup,utils,setup_logging}.bash root@$RMF_WEB_INSTANCE_NAME.local:~ 
scp -i $KEY $SCRIPTPATH/../../config/{cyclonedds,fastdds}.xml root@$RMF_WEB_INSTANCE_NAME.local:~
scp -i $KEY /tmp/$RMF_FS_INSTANCE_NAME.repos root@$RMF_WEB_INSTANCE_NAME.local:~/rmf.repos 
scp -i $KEY $1 root@$RMF_WEB_INSTANCE_NAME.local:~/config.yaml

lxc exec $RMF_WEB_INSTANCE_NAME -- bash -c "bash /root/web_bootstrap.bash /root/config.yaml"
lxc stop $RMF_WEB_INSTANCE_NAME > /dev/null 2>&1
