#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))
source $SCRIPTPATH/utils.bash
export_config_vars $1
RMF_WEB_INSTANCE_NAME=$RMF_FS_INSTANCE_NAME-web

rmf_ip=`get_lxc_ip $RMF_FS_INSTANCE_NAME eth0`
sed -i "/$rmf_ip.*/d" /etc/hosts

web_ip=`get_lxc_ip $RMF_WEB_INSTANCE_NAME eth0`
sed -i "/$web_ip.*/d" /etc/hosts

lxc delete $RMF_FS_INSTANCE_NAME --force || true
lxc delete $RMF_WEB_INSTANCE_NAME --force || true
