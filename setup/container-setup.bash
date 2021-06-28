#!/usr/bin/env bash

env > /dev/null 2>&1

if [ -z "$1" ]
  then
    echo "Usage: bash container_setup.bash [path-to-config-file]"
    exit 1
fi

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

parse_yaml_and_export(){
  export ${1::-1}=$2
}

get_repos_file(){
  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  rm /tmp/$2.repos > /dev/null 2>&1 || true
  if [[ $1 =~ $regex ]]; then wget $1 -O /tmp/$2.repos; else cp $1 /tmp/$2.repos; fi
}


mainmenu() {
    whiptail \
        --title "RMF Fullstack Container Setup" \
        --menu "RMF Fullstack Host Container Steps" \
        --clear --ok-button 'Select' \
        $LINES $(($COLUMNS-8)) $(( $LINES-8 ))  \
        "Setup RMF Container"     "| Set Up the RMF Container" \
        "Setup rmf-web"           "| Set Up the rmf-web Container" \
        "Setup VPN"               "| [Root] Set Up VPN (Wireguard) to connect all devices" \
        "Deploy Config Files"     "| [Root] Deploy all configuration files" \
        "Delete"                  "| Delete all containers associated with this config file" \
        3>&1 1>&2 2>&3
}


if [ ! -f $1 ]; then 
    echo "Configuration file does not exist at $1"
    exit 1
fi 

while read envname; do [[ $envname == \#* ]] || parse_yaml_and_export $envname; done < $1

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
END

whiptail --textbox $help_textbox --title "Configuration" $LINES $COLUMNS 

while true; do
    case $(mainmenu) in
        "Setup RMF Container")
            get_repos_file $RMF_FS_VCS_REPO $RMF_FS_INSTANCE_NAME 
            bash $SCRIPTPATH/scripts/setup_rmf_container.bash $RMF_FS_INSTANCE_NAME
            ;;
        "Setup rmf-web")
            bash $SCRIPTPATH/scripts/setup_rmf_web_container.bash $RMF_FS_INSTANCE_NAME $RMF_FS_URL
            ;;
        "Setup VPN")
            sudo bash $SCRIPTPATH/scripts/setup_vpn.bash $RMF_FS_INSTANCE_NAME
            ;;
        "Deploy Config Files")
            sudo bash $SCRIPTPATH/scripts/deploy_configs.bash $RMF_FS_INSTANCE_NAME $RMF_FS_URL $RMF_FS_ROS_VERSION $RMF_FS_ROS_DOMAIN_ID $RMF_FS_RMW_IMPLEMENTATION $RMF_FS_WEBSOCKET_PORT
            ;;
        "Delete")
            bash $SCRIPTPATH/scripts/delete.bash
            ;;
        *)
            break
    esac
    read -n 1 -s -r -p "Press any key to continue"$'\n'
done

