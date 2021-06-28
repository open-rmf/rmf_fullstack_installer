#!/usr/bin/env bash

env > /dev/null 2>&1

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

mainmenu() {
    whiptail \
        --title "RMF Fullstack Host Setup" \
        --menu "RMF Fullstack Host Setup Steps" \
        --clear --ok-button 'Select' \
        $LINES $(($COLUMNS-8)) $(( $LINES-8 ))  \
        "TLS Setup"       "| [Root] Set Up TLS certificates with Let's Encrypt" \
        "VNC Setup"       "| [Root] Install Graphical UI and VNC server" \
        "noVNC Web Setup" "| [Root] Set up VNC for access over Web" \
        "LXC Setup"       "| Set up profiles and networking for LXC" \
        "Manage VNC"      "| [Root] Start, Stop and Switch between VNC Servers" \
        3>&1 1>&2 2>&3
}

while true; do
    case $(mainmenu) in
        "TLS Setup")
            sudo bash $SCRIPTPATH/scripts/tls_setup.bash
            ;;
        "VNC Setup")
            sudo bash $SCRIPTPATH/scripts/vnc_setup.bash
            ;;
        "noVNC Web Setup")
            sudo bash $SCRIPTPATH/scripts/novnc_setup.bash
            ;;
        "LXC Setup")
            bash $SCRIPTPATH/scripts/lxc_setup.bash
            ;;
        "Manage VNC")
            sudo bash $SCRIPTPATH/scripts/manage_vnc.bash
            ;;
        *)
            break
    esac
    read -n 1 -s -r -p "Press any key to continue"$'\n'
done

