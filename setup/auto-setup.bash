#!/bin/bash 
set -e

env > /dev/null 2>&1

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if [ -z "$1" ]
  then
    echo "Usage: bash container_setup.bash [path-to-config-file]"
    exit 1
fi

if [ ! -f $1 ]; then 
    echo "Configuration file does not exist at $1"
    exit 1
fi 

# Load Config
source $SCRIPTPATH/scripts/container/utils.bash
export_config_vars $1

# Delete existing containers
sudo bash $SCRIPTPATH/scripts/container/delete.bash $1 || true

# Download repos file
get_repos_file $RMF_FS_VCS_REPO $RMF_FS_INSTANCE_NAME 

# Set up rmf and rmf-web LXC containers
bash $SCRIPTPATH/scripts/container/setup_rmf_container.bash $1
bash $SCRIPTPATH/scripts/container/setup_rmf_web_container.bash $1

# Deploy wireguard and routing configs
sudo bash $SCRIPTPATH/scripts/container/setup_vpn.bash $1
sudo bash $SCRIPTPATH/scripts/container/deploy_configs.bash $1
