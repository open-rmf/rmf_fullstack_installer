#!/bin/bash
set -e

help_textbox=$(mktemp)
cat << END > $help_textbox
This step will import icons from a target resource folder to your rmf-web dashboard for display.

You can either import resources from the web, like this link:
https://github.com/open-rmf/rmf_demos/tree/main/rmf_demos_dashboard_resources/office

Or you can specify an absolute path in the rmf-web machine. 
The structure of the folder must be set correctly so the correct icons can be found.
Reference: https://github.com/open-rmf/rmf_demos/tree/main/rmf_demos_dashboard_resources/office
END

whiptail --textbox $help_textbox --title "Setup Icons" $LINES $COLUMNS 

SCRIPTPATH=$(dirname $(realpath "$0"))
source $SCRIPTPATH/utils.bash
export_config_vars $1
RMF_WEB_INSTANCE_NAME=$RMF_FS_INSTANCE_NAME-web
example_deployment_ws=/home/web/rmf-web/example-deployment

lxc info $RMF_WEB_INSTANCE_NAME &> /dev/null || { echo "Please Create rmf-web container for $RMF_FS_INSTANCE_NAME first."; exit 1; }

lxc restart $RMF_WEB_INSTANCE_NAME > /dev/null 2>&1 || lxc start $RMF_WEB_INSTANCE_NAME

echo "Rebuilding Dashboard"

lxc exec rmf-web -- sudo --login --user web bash -ilc "node /home/web/rmf-web/packages/dashboard/scripts/setup/setup.js" && lxc exec rmf-web -- sudo --login --user web bash -ilc "node /home/web/rmf-web/packages/dashboard/scripts/setup/get-icons.js" && lxc exec rmf-web -- sudo --login --user web bash -ilc "cd $example_deployment_ws && docker build -t rmf-web/dashboard -f docker/dashboard.dockerfile  /home/web/rmf-web/ && docker save rmf-web/dashboard -o dashboard.zip && docker load -i dashboard.zip && kubectl delete -f k8s/dashboard.yaml && kubectl apply -f k8s/dashboard.yaml" 

lxc exec rmf-web -- sudo --login --user web bash -ilc "kubectl delete -f $example_deployment_ws/k8s/dashboard.yaml; kubectl apply -f $example_deployment_ws/k8s/dashboard.yaml" 
