apt remove wazuh-dashboard -y
cd ..

# Copy prebuilt packages
cp -r ./packages/ ~/packages/

# Go to dashboard build tools
cd ./wazuh-dashboard-VX/dev-tools/build-packages/

# Build the dashboard .deb package
./build-packages.sh --commit-sha 5cb6f9a0ed-4a0e79949-b0c6e09 -r 1 --deb \
  -a file://$HOME/packages/wazuh-package.zip \
  -s file://$HOME/packages/security-package.zip \
  -b file://$HOME/packages/dashboard-package.zip

# Go to build output
cd output/

# Install the generated dashboard package
sudo dpkg -i wazuh-dashboard_4.12.0-1_amd64_5cb6f9a0ed-4a0e79949-b0c6e09.deb
sudo apt-get install -f   # fix dependencies if needed

# Enable and start the dashboard service
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
sudo systemctl status wazuh-dashboard

# Go back to installer folder
cd ../../../../WazuhVX-Install

# Prepare certificates for the dashboard
mkdir /etc/wazuh-dashboard/certs
tar -xf ./wazuh-certificates.tar -C /etc/wazuh-dashboard/certs/ ./node-1.pem ./node-1-key.pem ./root-ca.pem
mv -n /etc/wazuh-dashboard/certs/node-1.pem /etc/wazuh-dashboard/certs/dashboard.pem
mv -n /etc/wazuh-dashboard/certs/node-1-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
chmod 500 /etc/wazuh-dashboard/certs
chmod 400 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

IP=$(hostname -I | awk '{print $1}')

# Dashboard config (OpenSearch connection + SSL setup)
cat > /etc/wazuh-dashboard/opensearch_dashboards.yml <<EOF
server.host: 0.0.0.0
server.port: 443
opensearch.hosts: https://$IP:9200
opensearch.ssl.verificationMode: certificate
#opensearch.username:
#opensearch.password:
opensearch.requestHeadersAllowlist: ["securitytenant","Authorization"]
opensearch_security.multitenancy.enabled: false
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
server.ssl.enabled: true
server.ssl.key: "/etc/wazuh-dashboard/certs/dashboard-key.pem"
server.ssl.certificate: "/etc/wazuh-dashboard/certs/dashboard.pem"
opensearch.ssl.certificateAuthorities: ["/etc/wazuh-dashboard/certs/root-ca.pem"]
uiSettings.overrides.defaultRoute: /app/wz-home
EOF

systemctl stop filebeat
curl -so template.json https://raw.githubusercontent.com/wazuh/wazuh/v4.12.0/extensions/elasticsearch/7.x/wazuh-template.json
curl -XPUT -k -u admin:admin 'https://127.0.0.1:9200/_template/wazuh' -H 'Content-Type: application/json' -d @template.json

# Reload and restart dashboard service
systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl restart filebeat
systemctl restart wazuh-manager
systemctl restart wazuh-indexer
systemctl restart wazuh-dashboard
