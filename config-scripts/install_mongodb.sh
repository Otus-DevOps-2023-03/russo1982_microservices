#!/bin/bash

# --------------------------------------------------------------------------------------------
# Current script installs MongoDB ( mongodb-org )
#
# Special thanks to:
#   blacktm script, found here:
#   https://gist.github.com/blacktm/8302741
# --------------------------------------------------------------------------------------------


# Welcome message
echo "This will install MongoDB on the current machine."

# Prompt to continue
#read -p "  Continue? (y/n) " ans
#if [[ $ans != "y" ]]; then
#  echo -e "\nQuitting...\n"
#  exit
#fi
#echo

# Time the install process
START_TIME=$SECONDS

# Add GPG key and MongoDB repo
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

# update the list of packages available to install
sudo apt update

# install MongoDB
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod

# Print the time elapsed
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo -e "\nFinished in $(($ELAPSED_TIME/60/60)) hr, $(($ELAPSED_TIME/60%60)) min, and $(($ELAPSED_TIME%60)) sec\n"
echo "------------------------------------------------"
echo "Installed MongoDB version is:  $(mongod --version)"

