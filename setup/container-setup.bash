#!/bin/bash 

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

source $SCRIPTPATH/scripts/container/utils.bash
export_config_vars $1

mainmenu() {
    whiptail \
        --title "RMF Fullstack Container Setup" \
        --menu "RMF Fullstack Host Container Steps" \
        --clear --ok-button 'Select' \
        $LINES $(($COLUMNS-8)) $(( $LINES-8 ))  \
        "Setup RMF Container"     "| Provision + bootstrap an RMF container" \
        "Setup rmf-web Container" "| Provision + bootstrap an rmf-web container" \
        "RMF bootstrap"           "| [Root] Installs ROS2, RMF on the local machine" \
        "rmf-web bootstrap"       "| [Root] Deploys rmf-web on the local machine. A user 'web' will be created." \
        "Setup VPN"               "| [Root] Set Up VPN (Wireguard) to connect all devices" \
        "Deploy Config Files"     "| [Root] Deploy all configuration files" \
        "Setup Icons"		      "| Optionally set up icons on your rmf-web machine" \
        "Delete Containers"       "| [Root] Delete all containers and configs associated with this config file" \
        3>&1 1>&2 2>&3
}

help_textbox=$(mktemp)
cat << END > $help_textbox
Check the environment variables are loaded correctly:
RMF_FS_URL: $RMF_FS_URL
RMF_FS_INSTANCE_NAME: $RMF_FS_INSTANCE_NAME
RMF_FS_VCS_REPO: $RMF_FS_VCS_REPO
RMF_FS_ROS_VERSION: $RMF_FS_ROS_VERSION
RMF_FS_ROS_DOMAIN_ID: $RMF_FS_ROS_DOMAIN_ID
RMF_FS_RMW_IMPLEMENTATION: $RMF_FS_RMW_IMPLEMENTATION
RMF_FS_WEBSOCKET_PORT: $RMF_FS_WEBSOCKET_PORT
RMF_FS_WIREGUARD_SUBNET: $RMF_FS_WIREGUARD_SUBNET
RMF_FS_SERVER_EXTERNAL_IP: $RMF_FS_SERVER_EXTERNAL_IP
END

whiptail --textbox $help_textbox --title "Configuration" $LINES $COLUMNS 

while true; do
    case $(mainmenu) in
        "Setup RMF Container")
            get_repos_file $RMF_FS_VCS_REPO $RMF_FS_INSTANCE_NAME 
            bash $SCRIPTPATH/scripts/container/setup_rmf_container.bash $1
            ;;
        "Setup rmf-web Container")
            bash $SCRIPTPATH/scripts/container/setup_rmf_web_container.bash $1
            ;;
        "RMF bootstrap")
            get_repos_file $RMF_FS_VCS_REPO $RMF_FS_INSTANCE_NAME 
            sudo cp /tmp/$RMF_FS_INSTANCE_NAME.repos /root/rmf.repos
            sudo bash $SCRIPTPATH/scripts/container/rmf_bootstrap.bash $1
            ;;
        "rmf-web bootstrap")
            get_repos_file $RMF_FS_VCS_REPO $RMF_FS_INSTANCE_NAME 
            sudo cp /tmp/$RMF_FS_INSTANCE_NAME.repos /root/rmf.repos
            sudo bash $SCRIPTPATH/scripts/container/web_bootstrap.bash $1
            ;;
        "Setup VPN")
            sudo bash $SCRIPTPATH/scripts/container/setup_vpn.bash $1
            ;;
        "Deploy Config Files")
            sudo bash $SCRIPTPATH/scripts/container/deploy_configs.bash $1
            ;;
        "Setup Icons")
            sudo bash $SCRIPTPATH/scripts/container/web_icons_setup.bash $1
            ;;
        "Delete Containers")
            sudo bash $SCRIPTPATH/scripts/container/delete.bash $1
            ;;
        *)
            break
    esac
    read -n 1 -s -r -p "Press any key to continue"$'\n'
done

