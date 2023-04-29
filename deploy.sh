#!/bin/bash

# --------------------------------------------------------------------------------------------
# Current script a software from https://github.com/express42/reddit.git 
#
#Special thanks to:
#   blacktm script, found here:
#   https://gist.github.com/blacktm/8302741
# --------------------------------------------------------------------------------------------


# Welcome message
echo "This will deploy a software from https://github.com/express42/reddit.git"
echo
# Prompt to continue
#read -p "  Continue? (y/n) " ans
#if [[ $ans != "y" ]]; then
#  echo -e "\nQuitting...\n"
#  exit
#fi
#echo

# Time the install process
START_TIME=$SECONDS

# Check if git installed
GIT_INSTALLED=$(which git)

if [[ $GIT_INSTALLED == "" ]]; then
  echo " ----- ----- ---->> git is missing and will be installed"
  echo
  sudo apt-get install -y git # installing git
fi

# clone git repo of reddit
cd $HOME
git clone -b monolith https://github.com/express42/reddit.git

# Install Bundle settings
cd $HOME/reddit && bundle install

# Start puma deamon
puma -d


# Print the time elapsed
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo -e "\nFinished in $(($ELAPSED_TIME/60/60)) hr, $(($ELAPSED_TIME/60%60)) min, and $(($ELAPSED_TIME%60)) sec\n"
echo "------------------------------------------------"
ps aux | grep puma
echo
echo "Software is active"

