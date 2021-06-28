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
            sudo sh $SCRIPTPATH/scripts/install-aws-cli.sh
            ;;
        "Install Terraform")
            sudo sh $SCRIPTPATH/scripts/install-terraform.sh
            ;;
        "Configure AWS CLI")
            sh $SCRIPTPATH/scripts/configure-aws-cli.sh
            ;;
        "Generate AWS Keys")
            sh $SCRIPTPATH/scripts/generate-aws-keys.sh
            ;;
        "Provision")
            sh $SCRIPTPATH/scripts/provision.sh $SCRIPTPATH
            ;;
        "Destroy")
            sh $SCRIPTPATH/scripts/destroy.sh $SCRIPTPATH
            ;;
        *)
            break
    esac
    read -n 1 -s -r -p "Press any key to continue"$'\n'
done
