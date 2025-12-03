# Copy prebuilt packages
cp -r ../packages/ ~/

# Go to dashboard build tools
cd ../wazuh-dashboard-VX/dev-tools/build-packages/

# Build the dashboard .deb package
./build-packages.sh --commit-sha f1866b8bd8-c099f11fe-34ec8c2 -r 1 --deb \
  -a file://$HOME/packages/wazuh-package.zip \
  -s file://$HOME/packages/security-package.zip \
  -b file://$HOME/packages/dashboard-package.zip

# Go to build output
cd output/
cp -r * $HOME/VxPackage/