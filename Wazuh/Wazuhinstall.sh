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

clear
echo -e "${CYAN}-------------------------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}           WAZUH AUTO INSTALLATION SCRIPT VX                 ${RESET}"
echo -e "${CYAN}-------------------------------------------------------------${RESET}"

#######################
# PRECHECK: VxPackage #
#######################
PACKAGE_DIR="/root/VxPackage"

echo -e "${BOLD}${YELLOW}[CHECK]${RESET} Vérification du contenu du dossier ${CYAN}${PACKAGE_DIR}${RESET}..."

if [ ! -d "$PACKAGE_DIR" ]; then
    echo -e "${RED}[ERREUR]${RESET} Le dossier ${PACKAGE_DIR} n'existe pas."
    exit 1
fi

REQUIRED_FILES=(
    "wazuh-indexer-min_4.13.0_amd64.deb"
    "wazuh-manager_4.13.0-wazuhvoxy_amd64_2f1a131.deb"
    "wazuh-manager-dbg_4.13.0-wazuhvoxy_amd64_2f1a131.deb"
    "wazuh-dashboard_4.13.0-1_amd64_20fe390198-1eb4245ad-5857492.deb"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${PACKAGE_DIR}/${FILE}" ]; then
        echo -e "${RED}[ERREUR]${RESET} Fichier manquant : ${YELLOW}${FILE}${RESET}"
        MISSING=true
    fi
done

if [ "$MISSING" = true ]; then
    echo -e "${RED}[STOP]${RESET} Certains fichiers sont manquants dans ${PACKAGE_DIR}. Veuillez vérifier."
    exit 1
else
    echo -e "${GREEN}[OK]${RESET} Tous les fichiers requis sont présents."
fi

##########################
# STEP 1: DOWNLOAD TOOLS #
##########################
echo -e "${BOLD}${CYAN}[*] Téléchargement des outils nécessaires...${RESET}"
curl -sO https://packages.wazuh.com/4.13/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.13/config.yml

#########################
# STEP 2: CONFIGURATION #
#########################
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}[OK]${RESET} Adresse IP détectée : ${YELLOW}${SERVER_IP}${RESET}"

cat > config.yml <<EOF
nodes:
  indexer:
    - name: node-1
      ip: "$SERVER_IP"

  server:
    - name: wazuh-1
      ip: "$SERVER_IP"

  dashboard:
    - name: dashboard
      ip: "$SERVER_IP"
EOF

echo -e "${GREEN}[OK]${RESET} Fichier ${YELLOW}config.yml${RESET} généré avec succès."

########################
# STEP 3: CERTIFICATES #
########################
echo -e "${BOLD}${CYAN}[*] Génération des certificats Wazuh...${RESET}"
bash ./wazuh-certs-tool.sh -A >/dev/null 2>&1
tar -cvf ./wazuh-certificates.tar -C ./wazuh-certificates/ .
rm -rf ./wazuh-certificates
echo -e "${GREEN}[OK]${RESET} Certificats générés et archivés."

####################
# STEP 4: PACKAGES #
####################
echo -e "${BOLD}${CYAN}[*] Installation des paquets requis...${RESET}"
apt-get update -y >/dev/null 2>&1
apt install -y debconf adduser procps zip gnupg apt-transport-https >/dev/null 2>&1
echo -e "${GREEN}[OK]${RESET} Dépendances installées."

###################
# STEP 5: INDEXER #
###################
echo -e "${BOLD}${CYAN}[*] Installation de Wazuh Indexer...${RESET}"
apt install -y ${PACKAGE_DIR}/wazuh-indexer-min_4.13.0_amd64.deb >/dev/null 2>&1

NODE_NAME=node-1
mkdir -p /etc/wazuh-indexer/certs
tar -xf ./wazuh-certificates.tar -C /etc/wazuh-indexer/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./admin.pem ./admin-key.pem ./root-ca.pem

mv -n /etc/wazuh-indexer/certs/$NODE_NAME.pem /etc/wazuh-indexer/certs/indexer.pem
mv -n /etc/wazuh-indexer/certs/$NODE_NAME-key.pem /etc/wazuh-indexer/certs/indexer-key.pem

chmod 500 /etc/wazuh-indexer/certs
chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

systemctl daemon-reload
systemctl enable wazuh-indexer >/dev/null 2>&1
systemctl start wazuh-indexer

if systemctl is-active --quiet wazuh-indexer; then
    echo -e "${GREEN}[OK]${RESET} Service ${YELLOW}wazuh-indexer${RESET} démarré avec succès."
else
    echo -e "${RED}[ERREUR]${RESET} Le service ${YELLOW}wazuh-indexer${RESET} ne s’est pas lancé correctement."
    exit 1
fi

########################
# STEP 6: CLUSTER INIT #
########################
echo -e "${BOLD}${CYAN}[*] Initialisation du cluster...${RESET}"
/usr/share/wazuh-indexer/bin/indexer-security-init.sh
echo -e "${GREEN}[OK]${RESET} Cluster initialisé."

###################
# STEP 7: MANAGER #
###################
echo -e "${BOLD}${CYAN}[*] Installation du Wazuh Manager...${RESET}"
# bash Manager/Managerinstall.sh

#systemctl daemon-reload
#systemctl enable wazuh-manager >/dev/null 2>&1
#systemctl start wazuh-manager

#if systemctl is-active --quiet wazuh-manager; then
#    echo -e "${GREEN}[OK]${RESET} Service ${YELLOW}wazuh-manager${RESET} démarré avec succès."
#else
#    echo -e "${RED}[ERREUR]${RESET} Le service ${YELLOW}wazuh-manager${RESET} ne s’est pas lancé correctement."
#    exit 1
#fi

####################
# STEP 8: FILEBEAT #
####################
#echo -e "${BOLD}${CYAN}[*] Installation de Filebeat...${RESET}"
#sudo bash ./Filebeat/Filebeatinstall.sh
#echo -e "${GREEN}[OK]${RESET} Filebeat installé et configuré."

echo -e "${CYAN}-------------------------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}        INSTALLATION WAZUH VX TERMINÉE AVEC SUCCÈS ✅        ${RESET}"
echo -e "${CYAN}-------------------------------------------------------------${RESET}"
