cd ../
git clone -b v4.12.0 https://github.com/ELA-Voxy/wazuh-dashboard-plugins-VX.git
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

cd ../../../packages
zip -r -j ./security-package.zip ../wazuh-dashboard-VX/plugins/wazuh-security-dashboards-plugin/build/security-dashboards-2.*.*.0.zip
zip -r -j ./wazuh-package.zip ../wazuh-dashboard-VX/plugins/wazuh-check-updates/build/wazuhCheckUpdates-2.*.*.zip ../wazuh-dashboard-VX/plugins/main/build/wazuh-2.*.*.zip ../wazuh-dashboard-VX/plugins/wazuh-core/build/wazuhCore-2.*.*.zip

sudo bash ../WazuhVxInstall/Build/Rebuild.sh