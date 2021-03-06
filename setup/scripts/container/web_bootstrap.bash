#!/bin/bash

SCRIPTPATH=$(dirname $(realpath "$0"))

source $SCRIPTPATH/utils.bash
export_config_vars $1

bash $SCRIPTPATH/web_setup.bash $RMF_FS_URL
sudo -u web bash -c "cd /home/web; bash /home/web/deploy_web_setup.bash $RMF_FS_URL $RMF_FS_ROS_DOMAIN_ID $RMF_FS_RMW_IMPLEMENTATION $RMF_FS_ROS_VERSION" 
