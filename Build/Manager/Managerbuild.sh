#!/bin/bash

###########
# COLORS  #
###########
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

#########
# BUILD #
#########

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}            BUILD WAZUH MANAGER VX             ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

cd ~/
git clone https://github.com/ELA-Voxy/wazuh-VX.git && cd wazuh-VX && git checkout hotfix-v4.14.1

###########
# INSTALL #
###########

apt update
apt install python gcc g++ make libc6-dev curl policycoreutils automake autoconf libtool libssl-dev procps cmake build-dep python3 -y
echo "deb-src http://archive.ubuntu.com/ubuntu $(lsb_release -cs) main" >> /etc/apt/sources.list
cd packages/
sudo ./generate_package.sh -t manager -a amd64 -r wazuhvoxy --system deb
cd output/
sudo chmod a+rwx wazuh-manager_4.14.1-wazuhvoxy_amd64_578b501.deb
sudo chmod a+rwx wazuh-manager-dbg_4.14.1-wazuhvoxy_amd64_578b501.deb
ls -all
cp wazuh-manager_4.14.1-wazuhvoxy_amd64_578b501.deb $HOME/VxPackage/
cp wazuh-manager-dbg_4.14.1-wazuhvoxy_amd64_578b501.deb $HOME/VxPackage/
