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

###########
# CONFIGS #
###########
DEV_VERSION="4.13s"
WAZUH_VERSION="4.13.0"
INDEXER_VERSION="4.13.0-1"
PACKAGE_DIR="/root/VxPackage"
CERT_ARCHIVE="wazuh-certificates.tar"

#########
# UTILS #
#########
check_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERREUR]${RESET} $1"
        exit 1
    fi
}

require_cmds() {
    for cmd in "$@"; do
        if ! command -v $cmd &>/dev/null; then
            echo -e "${RED}[ERREUR]${RESET} Commande manquante : ${YELLOW}$cmd${RESET}"
            exit 1
        fi
    done
}

clear
echo -e "${CYAN}-------------------------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}           WAZUH AUTO INSTALLATION SCRIPT VX                 ${RESET}"
echo -e "${CYAN}-------------------------------------------------------------${RESET}"

##############################
# PRECHECK: Required tools   #
##############################
require_cmds curl gpg tar dpkg apt systemctl hostname awk

#######################
# PRECHECK: VxPackage #
#######################
echo -e "${BOLD}${YELLOW}[CHECK]${RESET} Vérification du contenu du dossier ${CYAN}${PACKAGE_DIR}${RESET}..."

if [ ! -d "$PACKAGE_DIR" ]; then
    echo -e "${RED}[ERREUR]${RESET} Le dossier ${PACKAGE_DIR} n'existe pas."
    exit 1
fi

REQUIRED_FILES=(
    "wazuh-manager_4.13.0-wazuhvoxy_amd64_2f1a131.deb"
    "wazuh-manager-dbg_4.13.0-wazuhvoxy_amd64_2f1a131.deb"
    "wazuh-dashboard_4.13.0-1_amd64_20fe390198-1eb4245ad-5857492.deb"
)

MISSING=false
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
curl -sfO https://packages.wazuh.com/${DEV_VERSION}/wazuh-certs-tool.sh
check_success "Échec téléchargement wazuh-certs-tool.sh"

curl -sfO https://packages.wazuh.com/${DEV_VERSION}/config.yml
check_success "Échec téléchargement config.yml"

#########################
# STEP 2: CONFIGURATION #
#########################
SERVER_IP=$(ip route get 1 | awk '{print $7; exit}')
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
echo -e "${GREEN}[OK]${RESET} Fichier config.yml généré."

########################
# STEP 3: CERTIFICATES #
########################
echo -e "${BOLD}${CYAN}[*] Génération des certificats Wazuh...${RESET}"
bash ./wazuh-certs-tool.sh -A >/dev/null
tar -cvf ./${CERT_ARCHIVE} -C ./wazuh-certificates/ .
rm -rf ./wazuh-certificates
echo -e "${GREEN}[OK]${RESET} Certificats générés et archivés."

####################
# STEP 4: PACKAGES #
####################
echo -e "${BOLD}${CYAN}[*] Installation des dépendances...${RESET}"
apt-get update -y >/dev/null
apt-get install -y debconf adduser procps zip gnupg apt-transport-https dnf dpkg >/dev/null
echo -e "${GREEN}[OK]${RESET} Dépendances installées."

###################
# STEP 5: INDEXER #
###################
echo -e "${BOLD}${CYAN}[*] Installation de Wazuh Indexer...${RESET}"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list
apt-get update -y >/dev/null
apt-get install -y wazuh-indexer=${INDEXER_VERSION}
check_success "Échec de l'installation de wazuh-indexer"

# Certificats
mkdir -p /etc/wazuh-indexer/certs
tar -xf ./${CERT_ARCHIVE} -C /etc/wazuh-indexer/certs/ ./node-1.pem ./node-1-key.pem ./admin.pem ./admin-key.pem ./root-ca.pem

mv -n /etc/wazuh-indexer/certs/node-1.pem /etc/wazuh-indexer/certs/indexer.pem
mv -n /etc/wazuh-indexer/certs/node-1-key.pem /etc/wazuh-indexer/certs/indexer-key.pem

chmod 500 /etc/wazuh-indexer/certs
chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

systemctl daemon-reload
systemctl enable wazuh-indexer >/dev/null
systemctl start wazuh-indexer

if systemctl is-active --quiet wazuh-indexer; then
    echo -e "${GREEN}[OK]${RESET} wazuh-indexer démarré."
else
    echo -e "${RED}[ERREUR]${RESET} Échec démarrage wazuh-indexer."
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
dpkg -i ${PACKAGE_DIR}/wazuh-manager_*.deb
dpkg -i ${PACKAGE_DIR}/wazuh-manager-dbg_*.deb

systemctl daemon-reload
systemctl enable wazuh-manager >/dev/null
systemctl start wazuh-manager

if systemctl is-active --quiet wazuh-manager; then
    echo -e "${GREEN}[OK]${RESET} wazuh-manager démarré."
else
    echo -e "${RED}[ERREUR]${RESET} Échec démarrage wazuh-manager."
    exit 1
fi

####################
# STEP 8: FILEBEAT #
####################
echo -e "${BOLD}${CYAN}[*] Installation de Filebeat...${RESET}"
bash ./Filebeat/Filebeatinstall.sh
echo -e "${GREEN}[OK]${RESET} Filebeat installé."

#####################
# STEP 9: DASHBOARD #
#####################
echo -e "${BOLD}${CYAN}[*] Installation de Wazuh Dashboard...${RESET}"
dpkg -i ${PACKAGE_DIR}/wazuh-dashboard_*.deb
apt-get install -f -y

# Certificats Dashboard
mkdir -p /etc/wazuh-dashboard/certs
tar -xf ./${CERT_ARCHIVE} -C /etc/wazuh-dashboard/certs/ ./node-1.pem ./node-1-key.pem ./root-ca.pem
mv -n /etc/wazuh-dashboard/certs/node-1.pem /etc/wazuh-dashboard/certs/dashboard.pem
mv -n /etc/wazuh-dashboard/certs/node-1-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
chmod 500 /etc/wazuh-dashboard/certs
chmod 400 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

cat > /etc/wazuh-dashboard/opensearch_dashboards.yml <<EOF
server.host: 0.0.0.0
server.port: 443
opensearch.hosts: https://${SERVER_IP}:9200
opensearch.ssl.verificationMode: certificate
opensearch.requestHeadersAllowlist: ["securitytenant","Authorization"]
opensearch_security.multitenancy.enabled: false
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
server.ssl.enabled: true
server.ssl.key: "/etc/wazuh-dashboard/certs/dashboard-key.pem"
server.ssl.certificate: "/etc/wazuh-dashboard/certs/dashboard.pem"
opensearch.ssl.certificateAuthorities: ["/etc/wazuh-dashboard/certs/root-ca.pem"]
uiSettings.overrides.defaultRoute: /app/wz-home
EOF

# Template Elasticsearch
systemctl stop filebeat
curl -sfO https://raw.githubusercontent.com/wazuh/wazuh/v${WAZUH_VERSION}/extensions/elasticsearch/7.x/wazuh-template.json
curl -XPUT -k -u admin:admin 'https://127.0.0.1:9200/_template/wazuh' \
     -H 'Content-Type: application/json' -d @wazuh-template.json

##########################
# STEP 10: FINAL RESTART #
##########################
echo -e "${BOLD}${CYAN}[*] Redémarrage des services...${RESET}"
for service in wazuh-indexer wazuh-manager wazuh-dashboard filebeat; do
    systemctl restart $service
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}[OK]${RESET} Service ${YELLOW}$service${RESET} démarré."
    else
        echo -e "${RED}[ERREUR]${RESET} Échec du démarrage de ${YELLOW}$service${RESET}."
    fi
done

####################
# STEP 11: CLEANUP #
####################
echo -e "${BOLD}${YELLOW}[CLEANUP]${RESET} Suppression des fichiers temporaires..."
# Sécurité du dépôt
sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list
apt-get update -y >/dev/null
rm -f config.yml wazuh-template.json ${CERT_ARCHIVE}

echo -e "${CYAN}-------------------------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}        INSTALLATION WAZUH VX TERMINÉE AVEC SUCCÈS ✅        ${RESET}"
echo -e "${CYAN}-------------------------------------------------------------${RESET}"
