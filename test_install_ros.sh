#!/bin/bash

# Set noninteractive frontend
export DEBIAN_FRONTEND=noninteractive

total_steps=17
current_step=0

function show_progress {
    current_step=$((current_step + 1))
    percentage=$((current_step * 100 / total_steps))
    printf "\r[%-50s] %d%% Step %d/%d: %s" $(printf "#%.0s" $(seq 1 $((percentage / 2)))) $percentage $current_step $total_steps "$1"
    echo
}

show_progress "Checking and setting locale"
locale
sudo apt-get update -y && sudo apt-get install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
locale

show_progress "Installing software-properties-common"
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y universe

show_progress "Installing curl and adding ROS2 repository"
sudo apt-get update -y && sudo apt-get install -y curl
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

show_progress "Updating and upgrading packages"
sudo apt-get update -y
sudo apt-get upgrade -y

show_progress "Installing ROS2 Humble base"
sudo apt-get install -y ros-humble-ros-base

show_progress "Installing ROS development tools"
sudo apt-get install -y ros-dev-tools

show_progress "Setting up ROS2 environment"
echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc
source ~/.bashrc

show_progress "Installing additional dependencies"
sudo apt-get install -y python3-argcomplete python3-colcon-common-extensions libboost-system-dev build-essential
sudo apt-get install -y ros-humble-hls-lfcd-lds-driver
sudo apt-get install -y ros-humble-turtlebot3-msgs
sudo apt-get install -y ros-humble-dynamixel-sdk
sudo apt-get install -y libudev-dev

show_progress "Creating TurtleBot3 workspace"
mkdir -p ~/turtlebot3_ws/src && cd ~/turtlebot3_ws/src
git clone -b humble-devel https://github.com/ROBOTIS-GIT/turtlebot3.git
git clone -b ros2-devel https://github.com/ROBOTIS-GIT/ld08_driver.git
cd ~/turtlebot3_ws/src/turtlebot3
rm -r turtlebot3_cartographer turtlebot3_navigation2
cd ~/turtlebot3_ws/
source ~/.bashrc

show_progress "Building TurtleBot3 packages"
colcon build --symlink-install --parallel-workers 1

show_progress "Setting up TurtleBot3 environment"
echo 'source ~/turtlebot3_ws/install/setup.bash' >> ~/.bashrc
source ~/.bashrc

show_progress "Setting up udev rules"
sudo cp `ros2 pkg prefix turtlebot3_bringup`/share/turtlebot3_bringup/script/99-turtlebot3-cdc.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

show_progress "Setting ROS domain ID and LDS model"
echo 'export ROS_DOMAIN_ID=10 #TURTLEBOT3' >> ~/.bashrc
echo 'export LDS_MODEL=LDS-02' >> ~/.bashrc
source ~/.bashrc

show_progress "Installation complete!"
echo "ROS2 and TurtleBot3 have been successfully installed."