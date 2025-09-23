########
# ROOT #
########

sudo bash ./Wazuh/Wazuhinstall.sh
sudo bash ./Manager/Managerinstall.sh

###########
# NO-ROOT #
###########

cd ..
bash ./WazuhVX-Install/Dashboard/Dashboardinstall.sh