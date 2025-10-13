#!/bin/bash

########
# ROOT #
########

sudo bash ./Wazuh/Wazuhinstall.sh

###########
# NO-ROOT #
###########

cd ..
bash ./WazuhVX-Install/Dashboard/Dashboardinstall.sh

#!/bin/bash

###########
# CREDITS #
###########
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

clear
echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}              WAZUH VX Install                ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${WHITE}                 Made By ELA                 ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}\n"

echo -e "${YELLOW}1)${RESET} ${WHITE}Install ?${RESET}"
echo -e "${YELLOW}2)${RESET} ${WHITE}Quitter${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

read -p "$(echo -e ${BOLD}${BLUE}👉 Choisis une option [1-2]: ${RESET})" choice

case $choice in
  1)
    echo -e "${GREEN}[*] Wazuh installing${RESET}"
    sudo bash Wazuh/Wazuhinstall.sh
    ;;
  2)
    echo -e "${RED}[*] Sortie du script.${RESET}"
    exit 0
    ;;
  *)
    echo -e "${RED}❌ Option invalide.${RESET}"
    ;;
esac
