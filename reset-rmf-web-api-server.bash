#!/bin/bash

PARAMS=""

while (( "$#" )); do
  case "$1" in
    --help)
      echo "Usage: reset-rmf-web-api-server webMachineName [login@hostname of machine running rmf-web] --webIdentityFile [path to ssh key of webMachineName"
      exit 0
      ;;
    -wi|--webIdentityFile)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	WEB_IDENTITY_FILE=$2
        shift 2
      else
        echo "Error: Argument for $1 (webIdentityFile) is missing" >&2
        exit 1
      fi
      ;;
    -w|--webMachineName)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        WEB_MACHINE_NAME=$2
        shift 2
      else
        echo "Error: Argument for $1 (webMachineName) is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

eval set -- "$PARAMS"

WEB_MACHINE_NAME="${WEB_MACHINE_NAME:-root@rmf-web.local}"
WEB_IDENTITY_FILE="${WEB_IDENTITY_FILE:-/home/ubuntu/.ssh/id_rmf}"

echo "WEB_MACHINE_NAME: $WEB_MACHINE_NAME"
echo "WEB_IDENTITY_FILE: $WEB_IDENTITY_FILE"

read -p "Continue? [Yy] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	ssh -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME "kubectl delete -f /home/web/rmf-web/example-deployment/k8s/rmf-server.yaml; kubectl apply -f /home/web/rmf-web/example-deployment/k8s/rmf-server.yaml"
	ssh -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME "wg-quick down wg0; wg-quick up wg0;"
else
  echo "Abort."
fi

