#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))
source $SCRIPTPATH/utils.bash
export_config_vars $1
RMF_WEB_INSTANCE_NAME=$RMF_FS_INSTANCE_NAME-web

sed -i "/$RMF_FS_INSTANCE_NAME.local/d" /etc/hosts
sed -i "/$RMF_WEB_INSTANCE_NAME.local/d" /etc/hosts

lxc delete $RMF_FS_INSTANCE_NAME --force || true
lxc delete $RMF_WEB_INSTANCE_NAME --force || true
