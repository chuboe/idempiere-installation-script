#!/bin/bash

# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
# chuboe_install_activemq.sh
# Notes:
#  - If you are running ActiveMQ and iDempiere on the same machine, you need at least 2GB of RAM
#  - This script is fully functioning as is. Just execute it.

DOWNLOAD="http://apache.tradebit.com/pub/activemq/5.10.0/apache-activemq-5.10.0-bin.tar.gz"
FILENAME="apache-activemq-5.10.0-bin.tar.gz"
FOLDER="apache-activemq-5.10.0"
ACTIVEMQ_USER="activemq"
OSUSER="ubuntu"
INSTALLPATH=/opt/$FOLDER
CONFIG_FILE="/etc/default/activemq"
TMP_DIR="/tmp/chuboe_activemq"
INITDNAME="activemq"

sudo apt-get update

#get rid of silly ubuntu sudo error in vpc - not needed if iDempeire already installed
#wget bitbucket.org/cboecking/idempiere-installation-script/raw/default/utils/setHostName.sh
#chmod +x setHostName.sh
#sudo ./setHostName.sh

mkdir $TMP_DIR
cd $TMP_DIR
wget $DOWNLOAD
sudo tar zxvf $FILENAME -C /opt/

cd $INSTALLPATH/bin

#commented out - sudo ./activemq configure  #is this needed?
sudo ./activemq setup $CONFIG_FILE

#change default user to ACTIVEMQ_USER
sudo sed -i 's|ACTIVEMQ_USER=""|ACTIVEMQ_USER='$ACTIVEMQ_USER'|' $CONFIG_FILE

#create activemq user
sudo useradd $ACTIVEMQ_USER

#add OSUSER (your username) to ACTIVEMQ_USER group
#NOTE: this setting will not take effect until after you restart your session
sudo usermod -a -G $ACTIVEMQ_USER $OSUSER

#restrict privilidges on CONFIG_FILE if you are concerned about security
sudo chown $ACTIVEMQ_USER:nogroup $CONFIG_FILE
sudo chmod 600 $CONFIG_FILE

#change /opt/folder ownership to ACTIVEMQ_USER
sudo chown -R $ACTIVEMQ_USER:$ACTIVEMQ_USER $INSTALLPATH

#manual start server
#NOTE: use ./activemq console to debug start issues
#sudo $INSTALLPATH/bin/activemq start

#add activemq as a service that boots automatically

cat <<EOT >> $TMP_DIR/$INITDNAME
#!/bin/bash
#
# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
#
# description: ActiveMQ is a JMS Messaging Queue Server.

RETVAL=0

umask 077

start() {
       echo -n $"Starting ActiveMQ: "
       cd $INSTALLPATH/bin
       ./activemq start
       echo
       return \$RETVAL
}
stop() {
       echo -n $"Shutting down ActiveMQ: "
       cd $INSTALLPATH/bin
       ./activemq stop
       echo
       return \$RETVAL
}
restart() {
       stop
       start
}
case "\$1" in
 start)
       start
       ;;
 stop)
       stop
       ;;
 restart|reload)
       restart
       ;;
 *)
       echo $"Usage: \$0 {start|stop|restart}"
       exit 1
esac

exit \$?
EOT

sudo mv $TMP_DIR/$INITDNAME /etc/init.d/
sudo chmod +x /etc/init.d/$INITDNAME
sudo update-rc.d $INITDNAME defaults
sudo /etc/init.d/$INITDNAME start

#test
#netstat -an|grep 61616

#http://activemq.apache.org/web-console.html
#navigate to url.com:8161 or url.com:8161/admin
#default username/password = admin/admin

#done