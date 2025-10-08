#!/bin/bash

###########
# NO-ROOT #
###########

bash Build/Dashboard/Dashboardbuild.sh

########
# ROOT #
########
sudo bash Build/CreateFolder.sh
sudo bash Build/Dashboard/Debbuild.sh
sudo bash Build/Indexer/Indexerbuild.sh
sudo bash Build/Manager/Managerbuild.sh