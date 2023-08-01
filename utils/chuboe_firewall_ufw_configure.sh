#!/bin/bash

# note: this is a copy paste reference - not recommended to run as a script

sudo apt update
sudo apt install -y ufw
#sudo ufw status
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow from some.ip.address.here to any port 5432 comment 'only allow app server to connect directly to the database'
# above shows how to add a comment to the rule for future reference
sudo ufw show added
# above shows rules even when not active
  # below is an alternative way to see rules when UFW inactive:
  sudo cat /etc/ufw/user.rules
sudo ufw enable
sudo ufw status
