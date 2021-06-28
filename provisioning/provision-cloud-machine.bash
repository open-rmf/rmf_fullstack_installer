#!/usr/bin/env bash

env > /dev/null 2>&1

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

mainmenu() {
    whiptail \
        --title "Provision Cloud Machine" \
        --menu "Cloud Provisioning Steps" \
        --clear --ok-button 'Select' \
        $LINES $(($COLUMNS-8)) $(( $LINES-8 ))  \
        "Install AWS CLI v2" "| [Root] Terminal interface to manage AWS resources." \
        "Install Terraform"  "| [Root] Provisioning Tool" \
        "Configure AWS CLI"  "| Log into AWS Command Line interface" \
        "Generate AWS Keys"  "| Create Public / Private Key Pairs" \
        "Provision"          "| Create the Teraform Instance" \
        "Destroy"            "| Destroy the Terraform Instance" \
        3>&1 1>&2 2>&3
}

while true; do
    case $(mainmenu) in
        "Install AWS CLI v2")
            sudo bash $SCRIPTPATH/scripts/install-aws-cli.bash
            ;;
        "Install Terraform")
            sudo bash $SCRIPTPATH/scripts/install-terraform.bash
            ;;
        "Configure AWS CLI")
            bash $SCRIPTPATH/scripts/configure-aws-cli.bash
            ;;
        "Generate AWS Keys")
            bash $SCRIPTPATH/scripts/generate-aws-keys.bash
            ;;
        "Provision")
            bash $SCRIPTPATH/scripts/provision.bash $SCRIPTPATH
            ;;
        "Destroy")
            bash $SCRIPTPATH/scripts/destroy.bash $SCRIPTPATH
            ;;
        *)
            break
    esac
    read -n 1 -s -r -p "Press any key to continue"$'\n'
done
