#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))

source $SCRIPTPATH/utils.bash
export_config_vars $1

bash /$SCRIPTPATH/rmf_setup.bash $RMF_FS_ROS_VERSION $RMF_FS_ROS_DOMAIN_ID $RMF_FS_RMW_IMPLEMENTATION
