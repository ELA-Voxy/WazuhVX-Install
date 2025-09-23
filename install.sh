########
# ROOT #
########

sudo bash ./Wazuh/Wazuhinstall.sh
sudo bash ./Manager/Managerinstall.sh
sudo bash ./Indexer/Indexerinstall.sh

###########
# NO-ROOT #
###########

cd ..
bash ./WazuhVX-Install/Dashboard/Dashboardinstall.sh