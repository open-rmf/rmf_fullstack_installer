#!/bin/bash

create_container() {
  echo "Creating container $1.."
  lxc launch ubuntu:20.04 $1
  lxc profile assign $1 default,nat
  lxc restart $1
}

eval_retry () {
while ! eval $1;
do
  echo "Retrying Command.."
  sleep 2
done
}

SCRIPTPATH=$(dirname $(realpath "$0"))

echo $1
lxc info $1 &> /dev/null || create_container $1
echo "Installing mDNS"; eval_retry "lxc exec $1 -- bash -c \"apt install avahi-daemon -y\"";

# SSH key generation
KEY=$HOME/.ssh/id_$1
PUBKEY=$KEY.pub
AUTHORIZED_KEYS=$HOME/.ssh/authorized_keys
KNOWN_HOSTS=$HOME/.ssh/known_hosts
[ -f $PUBKEY ] || ssh-keygen -f $KEY -N '' -C "key for local lxds"
chmod 0600 $KEY $PUBKEY
grep "$(cat $PUBKEY)" $AUTHORIZED_KEYS -qs || cat $PUBKEY >> $AUTHORIZED_KEYS

touch $KNOWN_HOSTS
ssh-keygen -f "$KNOWN_HOSTS" -R "$1.local"
eval_retry "lxc exec $1 -- bash -c \"echo $(cat $PUBKEY) >> /root/.ssh/authorized_keys\""
eval_retry "ssh -o StrictHostKeyChecking=no root@$1.local -i $KEY echo 'SSH over mDNS is successful'"

scp -i $KEY $SCRIPTPATH/rmf_setup.bash root@$1.local:~ 
scp -i $KEY /tmp/$1.repos root@$1.local:~/rmf.repos 
lxc exec $RMF_FS_INSTANCE_NAME -- bash -c "bash /root/rmf_setup.bash $RMF_FS_ROS_VERSION $RMF_FS_ROS_DOMAIN_ID $RMF_FS_RMW_IMPLEMENTATION"
