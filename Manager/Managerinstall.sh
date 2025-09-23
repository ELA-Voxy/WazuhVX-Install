#########
# BUILD #
#########

cd ~/
git clone https://github.com/ELA-Voxy/wazuh-VX.git && git checkout v4.13.0

###########
# INSTALL #
###########

apt-get update
apt-get install python gcc g++ make libc6-dev curl policycoreutils automake autoconf libtool libssl-dev procps cmake
echo "deb-src http://archive.ubuntu.com/ubuntu $(lsb_release -cs) main" >> /etc/apt/sources.list
apt-get update
apt-get build-dep python3 -y
./install.sh