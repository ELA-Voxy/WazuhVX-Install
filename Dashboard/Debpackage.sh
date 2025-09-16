cd ~/wazuh-dashboard-VX/dev-tools/build-packages/

./build-packages.sh --commit-sha 5cb6f9a0ed-4a0e79949-b0c6e09 -r 1 --deb -a file://$HOME/packages/wazuh-package.zip -s file://$HOME/packages/security-package.zip -b file://$HOME/packages/dashboard-package.zip