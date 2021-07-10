#!/bin/bash
set -e

SCRIPTPATH=$(dirname $(realpath "$0"))

# Set up ROS2
sudo apt update && sudo apt install curl gnupg2 lsb-release wget -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg  
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update

sudo apt install ros-$1-desktop -y

# Set up rmf-backend
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
wget https://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -

sudo apt update && sudo apt install \
          git cmake python3-vcstool curl \
            python3-pip \
              qt5-default \
                ignition-edifice -y

pip3 install flask-socketio
sudo apt-get install python3-colcon* -y
sudo apt install wmctrl ros-$1-rmw-cyclonedds-cpp -y
sudo apt install python3-rosdep -y

sudo rosdep init || true
rosdep update

mkdir -p /opt/rmf/src
cd /opt/rmf
cp /root/rmf.repos /opt/rmf/rmf.repos
vcs import src < rmf.repos
cd src
find . -type d -name .git -exec sh -c "cd \"{}\"/../ && pwd && git pull -f" \;

cd /opt/rmf
rosdep install --from-paths src --ignore-src --rosdistro $1 -yr

source /opt/ros/$1/setup.bash
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

