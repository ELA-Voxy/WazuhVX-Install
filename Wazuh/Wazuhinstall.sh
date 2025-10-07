#!/bin/bash

# Get script and config
curl -sO https://packages.wazuh.com/4.13/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.13/config.yml

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

# Package needed
apt-get install debconf adduser procps zip -y
apt-get install gnupg apt-transport-https -y

###########
# INDEXER #
###########
#curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
#echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
#apt-get update
#sudo apt install wazuh-indexer
sudo bash ./Indexer/Indexerinstall.sh

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

# apt-get -y install wazuh-manager
bash Manager/Managerinstall.sh

# Starting Wazuh Server
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl start wazuh-manager

############
# Filebeat #
############

sudo bash ./Filebeat/Filebeatinstall.sh
