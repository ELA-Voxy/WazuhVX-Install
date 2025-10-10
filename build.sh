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

sudo bash Build/CreateFolder.sh

clear
echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}                BUILD SELECTOR                ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${WHITE}                 Made By ELA                 ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}\n"

echo -e "${YELLOW}1)${RESET} ${WHITE}Indexer${RESET}"
echo -e "${YELLOW}2)${RESET} ${WHITE}Manager${RESET}"
echo -e "${YELLOW}3)${RESET} ${WHITE}Dashboard${RESET}"
echo -e "${YELLOW}4)${RESET} ${WHITE}ALL${RESET}"
echo -e "${YELLOW}5)${RESET} ${WHITE}Quitter${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

read -p "$(echo -e ${BOLD}${BLUE}👉 Choisis une option [1-4]: ${RESET})" choice

case $choice in
  1)
    echo -e "${GREEN}[*] Indexer Building${RESET}"
    sudo bash Build/Indexer/Indexerbuild.sh
    ;;
  2)
    echo -e "${GREEN}[*] Manager Building${RESET}"
    sudo bash Build/Manager/Managerbuild.sh
    ;;
  3)
    echo -e "${GREEN}[*] Dashboard Building${RESET}"
    sudo apt install zip
    bash Build/Dashboard/Dashboardbuild.sh
    ;;
  4)
    echo -e "${GREEN}[*] Build complet (no-root + root)...${RESET}"
    bash Build/Dashboard/Dashboardbuild.sh
    sudo bash Build/Dashboard/Debbuild.sh
    sudo bash Build/Indexer/Indexerbuild.sh
    sudo bash Build/Manager/Managerbuild.sh
    ;;
  5)
    echo -e "${RED}[*] Sortie du script.${RESET}"
    exit 0
    ;;
  *)
    echo -e "${RED}❌ Option invalide.${RESET}"
    ;;
esac
