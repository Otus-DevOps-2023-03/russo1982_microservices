#!/bin/bash

sudo echo '[Unit]' > /tmp/puma.service
sudo echo 'Description=Puma' >> /tmp/puma.service
sudo echo 'After=network.target' >> /tmp/puma.service
sudo echo '[Service]' >> /tmp/puma.service
sudo echo 'Type=simple' >> /tmp/puma.service
sudo echo 'WorkingDirectory=$HOME/reddit' >> /tmp/puma.service
sudo echo 'ExecStart=/usr/local/bin/puma' >> /tmp/puma.service
sudo echo 'Restart=on-failure' >> /tmp/puma.service
sudo echo '[Install]' >> /tmp/puma.service
sudo echo 'WantedBy=multi-user.target' >> /tmp/puma.service
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
cd $HOME/reddit

sudo apt-get install -y git # installing git

# clone git repo of reddit
cd $HOME
git clone -b monolith https://github.com/express42/reddit.git

# Install Bundle settings
cd $HOME/reddit && bundle install

# Start puma deamon
sudo systemctl daemon-reload && sudo systemctl start puma && sudo systemctl enable puma
