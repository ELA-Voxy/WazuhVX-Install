#########
# BUILD #
#########

cd ~/
git clone https://github.com/ELA-Voxy/wazuh-indexer-VX.git && cd wazuh-indexer-VX && git checkout v4.13.0
apt install -y dnf dpkg
cd docker/ci/ && bash ./ci.sh up
sudo docker exec -it --user root wi-build_4.13.0 bash packaging_scripts/build.sh -a x64 -d deb

sudo docker cp wi-build_4.13.0:/home/wazuh-indexer/artifacts/dist/wazuh-indexer-min_4.13.0_amd64.deb .
sudo dpkg -i wazuh-indexer-min_4.13.0_amd64.deb
