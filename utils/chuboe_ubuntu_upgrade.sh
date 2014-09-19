#!/bin/bash

# The purpose of this file is to upgrade your ubuntu instance with out upgrading to the next major version.
# To upgrade a whole major version, use "dist-upgrade" instead of "upgrade"
# Since the script installs postgresql through the apt-get process, the apt-get upgrade should also install security patches as well.
#  - I have not absolutely confirmed the above statement.

# References:
#  http://debian-handbook.info/browse/wheezy/sect.apt-get.html
#  http://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt
#  http://stackoverflow.com/questions/7039520/bash-how-to-detect-whether-apt-get-requires-a-reboot

# To use this file, do one of the following tasks:
#  1. run this periodically
#  2. create a cron job to run this every weekend. 
#		Make sure you have a process to monitoring when the server needs to be rebooted. 
#		It will not reboot by itself. The statement: [ -f /var/run/reboot-required ] will tell you if you need a reboot.
# 		Just in case you are monitoring such things.

unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade