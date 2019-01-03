#!/bin/bash
echo "This script modifies your system to support SSL"
echo "See https://certbot.eff.org for more information"
echo "Press [ENTER] to continue or ctrl-c to cancel"
read
echo "NOTE: You do NOT want the script to force SSL redirect. See notes at the end of the script for instructions for manual changes. Press [ENTER] to continue."
read
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python-certbot-apache
sudo certbot --apache
echo "See /etc/apache2/sites-enabled/000-webui.conf for instructions on how to manually force SSL"