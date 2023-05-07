#!/bin/bash

sudo apt-get install -y git # installing git

# clone git repo of reddit
cd /home/ubuntu
git clone -b monolith https://github.com/express42/reddit.git

# Install Bundle settings
cd /home/ubuntu/reddit && bundle install

sudo echo '[Unit]' > /tmp/puma.service
sudo echo 'Description=Puma Service' >> /tmp/puma.service
sudo echo '' >> /tmp/puma.service
sudo echo 'Wants=network.target' >> /tmp/puma.service
sudo echo 'After=network-online.target' >> /tmp/puma.service
sudo echo '' >> /tmp/puma.service
sudo echo '[Service]' >> /tmp/puma.service
sudo echo 'Type=simple' >> /tmp/puma.service
sudo echo 'ExecStart=/usr/local/bin/puma' >> /tmp/puma.service
sudo echo 'Restart=on-failure' >> /tmp/puma.service
sudo echo 'RestartSec=10' >> /tmp/puma.service
sudo echo 'KillMode=process' >> /tmp/puma.service
sudo echo '' >> /tmp/puma.service
sudo echo 'WorkingDirectory=/home/ubuntu/reddit' >> /tmp/puma.service
sudo echo '' >> /tmp/puma.service
sudo echo '[Install]' >> /tmp/puma.service
sudo echo 'WantedBy=multi-user.target' >> /tmp/puma.service
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo chmod 755 /etc/systemd/system/puma.service


# Start puma deamon
sudo systemctl daemon-reload
sudo systemctl start puma
sudo systemctl enable puma
