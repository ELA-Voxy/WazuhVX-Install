#!/bin/bash

# Get script and config
curl -sO https://packages.wazuh.com/4.12/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.12/config.yml

# Get Local IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# AutoSelect config.yml
cat > config.yml <<EOF
nodes:
  # Wazuh indexer nodes
  indexer:
    - name: node-1
      ip: "$SERVER_IP"
    #- name: node-2
    #  ip: "<indexer-node-ip>"
    #- name: node-3
    #  ip: "<indexer-node-ip>"

  # Wazuh server nodes
  # If there is more than one Wazuh server
  # node, each one must have a node_type
  server:
    - name: wazuh-1
      ip: "$SERVER_IP"
    #  node_type: master
    #- name: wazuh-2
    #  ip: "<wazuh-manager-ip>"
    #  node_type: worker
    #- name: wazuh-3
    #  ip: "<wazuh-manager-ip>"
    #  node_type: worker

  # Wazuh dashboard nodes
  dashboard:
    - name: dashboard
      ip: "$SERVER_IP"
EOF

echo "[OK] config.yml généré avec IP: $SERVER_IP"

# Gen certificates used by Wazuh Services
bash ./wazuh-certs-tool.sh -A
tar -cvf ./wazuh-certificates.tar -C ./wazuh-certificates/ .
rm -rf ./wazuh-certificates

###########
# INDEXER #
###########

# Dependencies
apt-get -y install debconf adduser procps
apt-get -y install gnupg apt-transport-https

# Add Wazuh REPO
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt-get update

# Install Indexer
apt-get -y install wazuh-indexer

# Indexer HTTPS
NODE_NAME=node-1
mkdir /etc/wazuh-indexer/certs
tar -xf ./wazuh-certificates.tar -C /etc/wazuh-indexer/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./admin.pem ./admin-key.pem ./root-ca.pem
mv -n /etc/wazuh-indexer/certs/$NODE_NAME.pem /etc/wazuh-indexer/certs/indexer.pem
mv -n /etc/wazuh-indexer/certs/$NODE_NAME-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
chmod 500 /etc/wazuh-indexer/certs
chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

# Indexer START
systemctl daemon-reload
systemctl enable wazuh-indexer
systemctl start wazuh-indexer

################
# CLUSTER INIT #
################

/usr/share/wazuh-indexer/bin/indexer-security-init.sh

###########
# Manager #
###########

apt-get -y install wazuh-manager

# Starting Wazuh Server
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl start wazuh-manager

############
# Filebeat #
############

# Init
apt-get -y install filebeat
curl -so /etc/filebeat/filebeat.yml https://packages.wazuh.com/4.12/tpl/wazuh/filebeat/filebeat.yml

# Keystore and password
filebeat keystore create
echo admin | filebeat keystore add username --stdin --force
echo admin | filebeat keystore add password --stdin --force

curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/v4.7.2/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json

curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.3.tar.gz | tar -xvz -C /usr/share/filebeat/module

# Certificates
mkdir /etc/filebeat/certs
tar -xf ./wazuh-certificates.tar -C /etc/filebeat/certs/ ./$NODE_NAME.pem ./$NODE_NAME-key.pem ./root-ca.pem
mv -n /etc/filebeat/certs/$NODE_NAME.pem /etc/filebeat/certs/filebeat.pem
mv -n /etc/filebeat/certs/$NODE_NAME-key.pem /etc/filebeat/certs/filebeat-key.pem
chmod 500 /etc/filebeat/certs
chmod 400 /etc/filebeat/certs/*
chown -R root:root /etc/filebeat/certs

# Starting
systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat

#############
# DASHBOARD #
#############

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

git clone -b v4.12.0 https://github.com/ELA-Voxy/wazuh-dashboard-VX.git && cd wazuh-dashboard-VX/ && git checkout hotfix-v4.12.0
nvm install $(cat .nvmrc)
nvm use $(cat .nvmrc)
npm install -g yarn
yarn osd bootstrap
yarn build-platform --linux --skip-os-packages --release

cd plugins/
git clone -b v4.12.0 https://github.com/ELA-Voxy/wazuh-security-dashboards-plugin-VX.git
mv wazuh-security-dashboards-plugin-VX/ wazuh-security-dashboards-plugin/
cd wazuh-security-dashboards-plugin/
yarn
yarn build

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

sudo apt install zip
cd ../../../
mkdir packages
cd packages
zip -r -j ./dashboard-package.zip ../wazuh-dashboard/target/opensearch-dashboards-2.*.*-linux-x64.tar.gz
zip -r -j ./security-package.zip ../wazuh-dashboard/plugins/wazuh-security-dashboards-plugin/build/security-dashboards-2.*.*.0.zip
zip -r -j ./wazuh-package.zip ../wazuh-dashboard/plugins/wazuh-check-updates/build/wazuhCheckUpdates-2.*.*.zip ../wazuh-dashboard/plugins/main/build/wazuh-2.*.*.zip ../wazuh-dashboard/plugins/wazuh-core/build/wazuhCore-2.*.*.zip
ls

