#############
# DASHBOARD #
#############

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

git clone -b hotfix-v4.13.1 https://github.com/ELA-Voxy/wazuh-dashboard-VX.git && cd wazuh-dashboard-VX/
nvm install $(cat .nvmrc)
nvm use $(cat .nvmrc)
npm install -g yarn
yarn osd bootstrap
yarn build-platform --linux --skip-os-packages --release

cd plugins/
git clone -b hotfix-v4.13.1 https://github.com/ELA-Voxy/wazuh-security-dashboards-plugin-VX.git
mv wazuh-security-dashboards-plugin-VX/ wazuh-security-dashboards-plugin/
cd wazuh-security-dashboards-plugin/
yarn
yarn build

cd ../
git clone -b hotfix-v4.13.1 https://github.com/ELA-Voxy/wazuh-dashboard-plugins-VX.git
mv wazuh-dashboard-plugins-VX/ wazuh-dashboard-plugins/
cd wazuh-dashboard-plugins/
nvm install $(cat .nvmrc)
nvm use $(cat .nvmrc)
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
mkdir packages
cd packages
zip -r -j ./dashboard-package.zip ../wazuh-dashboard-VX/target/opensearch-dashboards-2.*.*-linux-x64.tar.gz
zip -r -j ./security-package.zip ../wazuh-dashboard-VX/plugins/wazuh-security-dashboards-plugin/build/security-dashboards-2.*.*.0.zip
zip -r -j ./wazuh-package.zip ../wazuh-dashboard-VX/plugins/wazuh-check-updates/build/wazuhCheckUpdates-2.*.*.zip ../wazuh-dashboard-VX/plugins/main/build/wazuh-2.*.*.zip ../wazuh-dashboard-VX/plugins/wazuh-core/build/wazuhCore-2.*.*.zip
ls
