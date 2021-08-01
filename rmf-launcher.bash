#!/bin/bash

PARAMS=""

while (( "$#" )); do
  case "$1" in
    --help)
      echo "Usage: rmf-launcher --headless [0|1] --simTime [0|1] --world [world name] --package [ros2 package name] --machineName [login@hostname of machine running RMF] webMachineName [login@hostname of machine running rmf-web] --identityFile [path to ssh key of machineName] --webIdentityFile [path to ssh key of webMachineName"
      exit 0
      ;;
    -i|--identityFile)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	IDENTITY_FILE=$2
        shift 2
      else
        echo "Error: Argument for $1 (identityFile) is missing" >&2
        exit 1
      fi
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
    -h|--headless)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	HEADLESS=$2
        shift 2
      else
        echo "Error: Argument for $1 (headless) is missing" >&2
        exit 1
      fi
      ;;
    -s|--simTime)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
	USE_SIM_TIME=$2
        shift 2
      else
        echo "Error: Argument for $1 (useSimTime) is missing" >&2
        exit 1
      fi
      ;;
    -p|--package)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        RMF_PACKAGE=$2
        shift 2
      else
        echo "Error: Argument for $1 (package) is missing" >&2
        exit 1
      fi
      ;;
    -w|--world)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        RMF_SCENARIO=$2
        shift 2
      else
        echo "Error: Argument for $1 (world) is missing" >&2
        exit 1
      fi
      ;;
    -m|--machineName)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        RMF_MACHINE_NAME=$2
        shift 2
      else
        echo "Error: Argument for $1 (webMachineName) is missing" >&2
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
    -l|--levelName)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        LEVEL_NAME=$2
        shift 2
      else
        echo "Error: Argument for $1 (levelName) is missing" >&2
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

RMF_SCENARIO="${RMF_SCENARIO:-office}"
RMF_PACKAGE="${RMF_PACKAGE:-rmf_demos}"
RMF_MACHINE_NAME="${RMF_MACHINE_NAME:-root@rmf.local}"
WEB_MACHINE_NAME="${WEB_MACHINE_NAME:-root@rmf-web.local}"
HEADLESS="${HEADLESS:-0}"
USE_SIM_TIME="${USE_SIM_TIME:-false}"
IDENTITY_FILE="${IDENTITY_FILE:-/home/ubuntu/.ssh/id_rmf}"
WEB_IDENTITY_FILE="${WEB_IDENTITY_FILE:-/home/ubuntu/.ssh/id_rmf}"
LEVEL_NAME="${LEVEL_NAME:-L1}"

echo "RMF_MACHINE_NAME: $RMF_MACHINE_NAME"
echo "WEB_MACHINE_NAME: $WEB_MACHINE_NAME"
echo "IDENTITY_FILE: $IDENTITY_FILE"
echo "WEB_IDENTITY_FILE: $WEB_IDENTITY_FILE"
echo "RMF_PACKAGE: $RMF_PACKAGE"
echo "RMF_SCENARIO: $RMF_SCENARIO"
echo "HEADLESS: $HEADLESS"
echo "USE SIM TIME: $USE_SIM_TIME"
echo "LEVEL_NAME: $LEVEL_NAME"

read -p "Continue? [Yy] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	ssh -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME "pkill -f schedule_visualizer"
	ssh -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME "pkill -f visualization"
	ssh -X -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME ". .profile; nohup ros2 launch rmf_visualization visualization.launch.xml use_sim_time:=$USE_SIM_TIME viz_config_file:=/opt/rmf/src/demonstrations/rmf_demos/rmf_demos/launch/include/office/office.rviz headless:=1 map_name:=$LEVEL_NAME >\$HOME/.ros/log/current_launch.log 2>&1 &"
	ssh -X -t -i $IDENTITY_FILE $RMF_MACHINE_NAME ". .profile; ros2 launch $RMF_PACKAGE $RMF_SCENARIO.launch.xml headless:=$HEADLESS use_sim_time:=$USE_SIM_TIME | tee \$HOME/.ros/log/current_launch.log"
	ssh -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME "pkill -f schedule_visualizer"
	ssh -i $WEB_IDENTITY_FILE $WEB_MACHINE_NAME "pkill -f visualization"
else
  echo "Abort."
fi

