cp -r ../packages/ ~/packages/

cd ../wazuh-dashboard-VX/dev-tools/build-packages/

./build-packages.sh --commit-sha 5cb6f9a0ed-4a0e79949-b0c6e09 -r 1 --deb -a file://$HOME/packages/wazuh-package.zip -s file://$HOME/packages/security-package.zip -b file://$HOME/packages/dashboard-package.zip

cd ../wazuh-dashboard-VX/dev-tools/build-packages/output/

sudo dpkg -i wazuh-dashboard_4.12.0-1_amd64_5cb6f9a0ed-4a0e79949-b0c6e09.deb   
sudo apt-get install -f

sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
sudo systemctl status wazuh-dashboard

cd ../../../../WazuhVX-Install

mkdir /etc/wazuh-dashboard/certs
tar -xf ./wazuh-certificates.tar -C /etc/wazuh-dashboard/certs/ ./node-1.pem ./node-1-key.pem ./root-ca.pem
mv -n /etc/wazuh-dashboard/certs/node-1.pem /etc/wazuh-dashboard/certs/dashboard.pem
mv -n /etc/wazuh-dashboard/certs/node-1-key.pem /etc/wazuh-dashboard/certs/dashboard-key.pem
chmod 500 /etc/wazuh-dashboard/certs
chmod 400 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

cat > /etc/wazuh-dashboard/opensearch_dashboards.yml <<EOF
server.host: 0.0.0.0
server.port: 443
opensearch.hosts: https://192.168.201.129:9200
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

systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl start wazuh-dashboard