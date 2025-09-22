cd ~/
git clone https://github.com/ELA-Voxy/wazuh-VX.git && cd wazuh-VX/packages && git checkout v4.13.0
mkdir output
./generate_package.sh -s output/ -t manager -a amd64 -r 1 --system deb