#########
# BUILD #
#########

cd ~/
git clone https://github.com/ELA-Voxy/wazuh-VX.git && cd wazuh-VX && git checkout v4.13.0

###########
# INSTALL #
###########

apt-get update
apt-get install python gcc g++ make libc6-dev curl policycoreutils automake autoconf libtool libssl-dev procps cmake
echo "deb-src http://archive.ubuntu.com/ubuntu $(lsb_release -cs) main" >> /etc/apt/sources.list
apt-get update
apt-get build-dep python3 -y
cd packages/
# GEN PACKAGES IN /home/vxadmin/wazuh-VX/packages/output
sudo ./generate_package.sh -t manager -a amd64 -r wazuhvoxy --system deb
cd output/
sudo chmod a+rwx wazuh-manager_4.13.0-wazuhvoxy_amd64_2f1a131.deb
sudo chmod a+rwx wazuh-manager-dbg_4.13.0-wazuhvoxy_amd64_2f1a131.deb
ls -all
cp wazuh-manager_4.13.0-wazuhvoxy_amd64_2f1a131.deb $HOME/VxPackage/
cp wazuh-manager-dbg_4.13.0-wazuhvoxy_amd64_2f1a131.deb $HOME/VxPackage/
