#!/bin/bash
echo "This script modifies your system to support SSL"
echo "See https://certbot.eff.org for more information"
echo "Press ENTER to continue or Ctrl+c to abort"
read
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python-certbot-apache
sudo certbot --apache