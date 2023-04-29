#!/bin/bash

# --------------------------------------------------------------------------------------------
# Current script installs Ruby ( ruby-full ruby-bundler build-essential )
#
# Special thanks to:
#   blacktm script, found here:
#   https://gist.github.com/blacktm/8302741
# --------------------------------------------------------------------------------------------

# Set the Ruby version you want to install
# RUBY_VERSION=3.1.3

# Welcome message
echo -e "This will install Ruby on the current machine.\n"

# Prompt to continue
read -p "  Continue? (y/n) " ans
if [[ $ans != "y" ]]; then
  echo -e "\nQuitting...\n"
  exit
fi
echo

# Time the install process
START_TIME=$SECONDS

# update the list of packages available to install
sudo apt update

# install ruby
sudo apt install -y ruby-full ruby-bundler build-essential

# Print the time elapsed
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo -e "\nFinished in $(($ELAPSED_TIME/60/60)) hr, $(($ELAPSED_TIME/60%60)) min, and $(($ELAPSED_TIME%60)) sec\n"
echo "------------------------------------------------"
echo "Installed Ruby version is:  $(ruby -v)"
echo "Installed Bundler version is:  $(bundler -v)"

