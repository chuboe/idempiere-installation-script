#This file contains the commands needed to install activemq
#This is not a script yet. It is just a collection of commands for now.

#http://activemq.apache.org/getting-started.html#GettingStarted-StartingActiveMQ
#http://activemq.apache.org/download-archives.html

#get rid of silly ubuntu sudo error in vpc
wget bitbucket.org/cboecking/idempiere-installation-script/raw/default/utils/setHostName.sh
chmod +x setHostName.sh
sudo ./setHostName.sh

####Installing from scratch (if using apt-get to install skip to below ####)
sudo apt-get update
sudo apt-get -y install openjdk-6-jdk

#below is some mirror
wget http://apache.spinellicreations.com/activemq/5.9.1/apache-activemq-5.9.1-bin.tar.gz
tar zxvf apache-activemq-5.9.1-bin.tar.gz
sudo cp -r apache-activemq-5.9.1 /opt/activemq
cd /opt/activemq/bin
sudo ./activemq configure # I do not know if this is needed
sudo ./activemq start

#test
netstat -an|grep 61616

#http://activemq.apache.org/web-console.html
#navigate to url.com:8161
#default username/password = admin/admin

#done

####Installing from apt-get
#not recommended
## you are required to do too much extra stuff
## does not include the Manage ActiveMQ broker (web console)
sudo apt-get install -y activemq

#http://stackoverflow.com/questions/8880747/how-to-enable-instances-for-apache-activemq-running-on-ubuntu
sudo ln -s /etc/activemq/instances-available/main /etc/activemq/instances-enabled/main

#start
sudo service activemq start

#test
netstat -an|grep 61616