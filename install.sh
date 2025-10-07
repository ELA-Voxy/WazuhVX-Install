#!/bin/bash

########
# ROOT #
########

sudo bash ./Wazuh/Wazuhinstall.sh

###########
# NO-ROOT #
###########

cd ..
bash ./WazuhVX-Install/Dashboard/Dashboardinstall.sh
