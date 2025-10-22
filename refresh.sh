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
echo -e "${BOLD}${GREEN}        WAZUH - Refresh Passwords Tool        ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${WHITE}                Made By ELA                  ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}\n"

# Confirmation
echo -ne "${BOLD}${YELLOW}⚠️  Cette opération va régénérer tous les mots de passe Wazuh. Continuer ? (o/n): ${RESET} "
read confirm

if [[ "$confirm" != "o" && "$confirm" != "O" ]]; then
  echo -e "${RED}❌ Opération annulée par l'utilisateur.${RESET}"
  exit 0
fi

# Demande des identifiants API
echo -ne "${BOLD}${CYAN}👉 Entrez le nom d'utilisateur de l'API Wazuh : ${RESET}"
read api_user
echo -ne "${BOLD}${CYAN}🔑 Entrez le mot de passe de l'API Wazuh : ${RESET}"
read -s api_pass
echo -e "\n"

# Télécharger le script officiel
echo -e "${BLUE}[*] Téléchargement de l'outil de mots de passe...${RESET}"
curl -so wazuh-passwords-tool.sh https://packages.wazuh.com/4.13/wazuh-passwords-tool.sh

# Vérifier le téléchargement
if [[ ! -f wazuh-passwords-tool.sh ]]; then
  echo -e "${RED}❌ Échec du téléchargement. Vérifie ta connexion.${RESET}"
  exit 1
fi

# Donner les droits d'exécution
chmod +x wazuh-passwords-tool.sh

# Exécuter l'outil de mise à jour
echo -e "${GREEN}[*] Exécution de l'outil de rafraîchissement des mots de passe...${RESET}"
sudo bash wazuh-passwords-tool.sh -a -A -au "$api_user" -ap "$api_pass"

# Nettoyage (optionnel)
# rm -f wazuh-passwords-tool.sh

echo -e "\n${GREEN}✅ Rafraîchissement terminé.${RESET}"
