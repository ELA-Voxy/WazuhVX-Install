# Copy prebuilt packages
cp -r ../packages/ ~/

# Go to dashboard build tools
cd ../wazuh-dashboard-VX/dev-tools/build-packages/

# Build the dashboard .deb package
./build-packages.sh --commit-sha 20fe390198-1eb4245ad-5857492 -r 1 --deb \
  -a file://$HOME/packages/wazuh-package.zip \
  -s file://$HOME/packages/security-package.zip \
  -b file://$HOME/packages/dashboard-package.zip

# Go to build output
cd output/
cp -r * $HOME/VxPackage/