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
git clone https://github.com/ELA-Voxy/wazuh-indexer-VX.git && cd wazuh-indexer-VX && git checkout v4.13.0
apt install -y dnf dpkg
cd docker/ci/ && bash ./ci.sh up
sudo docker exec -it --user root wi-build_4.13.0 bash packaging_scripts/build.sh -a x64 -d deb
sudo docker cp wi-build_4.13.0:/home/wazuh-indexer/artifacts/dist/wazuh-indexer-min_4.13.0_amd64.deb $HOME/VxPackage/