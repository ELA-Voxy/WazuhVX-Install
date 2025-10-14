#!/bin/bash

##########
# COLORS #
##########
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

#########
# CHECK #
#########

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}            BUILD WAZUH INDEXER VX             ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker isn't installed ! ${RESET}"
    exit 1
fi

#########
# BUILD #
#########

cd ~/
git clone https://github.com/ELA-Voxy/wazuh-indexer-VX.git 
cd wazuh-indexer-VX
git checkout v4.13.0
apt install openjdk-17-jdk binutils maven debmake debhelper dh-make build-essential -y
rm -rf /root/wazuh-indexer-VX/artifacts/tmp/
bash packaging_scripts/build.sh -a x64 -d deb -n $(bash packaging_scripts/baptizer.sh -a x64 -d deb -m)
bash packaging_scripts/assemble.sh -a x64 -d deb