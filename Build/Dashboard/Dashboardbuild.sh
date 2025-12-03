#!/bin/bash

###########
# COLORS  #
###########
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

#############
# DASHBOARD #
#############

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}           BUILD WAZUH DASHBOARD VX            ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

DASHBOARD_SOURCE_DIR="wazuh-dashboard-VX"

echo -e "${CYAN}${BOLD}=====================================================${RESET}"
echo -e "${CYAN}Gestion de la COMPILATION INCÉMENTIELLE : Conservation de node_modules${RESET}"
echo -e "${CYAN}=====================================================${RESET}"

if [ -d "$DASHBOARD_SOURCE_DIR" ]; then
    echo -e "${YELLOW}🔄 SOURCES DÉJÀ CLONÉES : Mise à jour par 'git pull' pour conserver les dépendances...${RESET}"
    cd "$DASHBOARD_SOURCE_DIR" || { echo "Erreur: Impossible d'accéder à $DASHBOARD_SOURCE_DIR"; exit 1; }
    git pull origin hotfix-v4.14.1
    
    echo -e "${YELLOW}🧹 Nettoyage des dossiers 'build' et 'target' internes...${RESET}"
    rm -rf plugins/wazuh-security-dashboards-plugin/build
    rm -rf plugins/wazuh-dashboard-plugins/plugins/main/build
    rm -rf plugins/wazuh-dashboard-plugins/plugins/wazuh-core/build
    rm -rf plugins/wazuh-dashboard-plugins/plugins/wazuh-check-updates/build
    rm -rf target 
    
    cd ..
else
    echo -e "${CYAN}🆕 SOURCES NON CLONÉES : Démarrage du 'git clone' initial...${RESET}"
    
    # Le 'git clone' initial est conservé ici
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    export OPENSEARCH_DASHBOARDS_VERSION="2.19.3"

    git clone -b hotfix-v4.14.1 https://github.com/ELA-Voxy/wazuh-dashboard-VX.git && cd wazuh-dashboard-VX/
    nvm install $(cat .nvmrc)
    nvm use $(cat .nvmrc)
    npm install -g yarn
    yarn osd bootstrap
    
    cd ..
fi

cd "$DASHBOARD_SOURCE_DIR" || { echo "Erreur: Impossible d'accéder à $DASHBOARD_SOURCE_DIR après clone/pull"; exit 1; }
echo -e "${CYAN}⚙️ Exécution des builds de plateforme et des plugins...${RESET}"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use $(cat .nvmrc)
yarn build-platform --linux --skip-os-packages --release
cd plugins/
rm -rf wazuh-security-dashboards-plugin wazuh-dashboard-plugins

git clone -b hotfix-v4.14.1 https://github.com/ELA-Voxy/wazuh-security-dashboards-plugin-VX.git
mv wazuh-security-dashboards-plugin-VX/ wazuh-security-dashboards-plugin/
cd wazuh-security-dashboards-plugin/
yarn
yarn build

cd ../
git clone -b hotfix-v4.14.1 https://github.com/ELA-Voxy/wazuh-dashboard-plugins-VX.git
mv wazuh-dashboard-plugins-VX/ wazuh-dashboard-plugins/
cd wazuh-dashboard-plugins/
cp -r plugins/* ../
cd ../main
yarn
yarn build
cd ../wazuh-core/
yarn
yarn build
cd ../wazuh-check-updates/
yarn
yarn build

cd ../../../
mkdir -p packages 
cd packages
zip -r -j ./dashboard-package.zip ../wazuh-dashboard-VX/target/opensearch-dashboards-2.*.*-linux-x64.tar.gz
zip -r -j ./security-package.zip ../wazuh-dashboard-VX/plugins/wazuh-security-dashboards-plugin/build/security-dashboards-2.*.*.0.zip
zip -r -j ./wazuh-package.zip ../wazuh-dashboard-VX/plugins/wazuh-check-updates/build/wazuhCheckUpdates-2.*.*.zip ../wazuh-dashboard-VX/plugins/main/build/wazuh-2.*.*.zip ../wazuh-dashboard-VX/plugins/wazuh-core/build/wazuhCore-2.*.*.zip

sudo bash ~/WazuhVX-Install/Build/Dashboard/Debbuild.sh
