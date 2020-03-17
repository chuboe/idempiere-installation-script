#!/bin/bash
# Version 1 Chuck Boecking - created

# This script uses rsync to restore a production webui server from a production primary or services server
# This script series assumes that the chuboe installation script was used to install iD on both servers
# This script assumes that you can ssh into the primary server via the idempiere user
# You can use the chuboe_adduser_os.sh script to create idempiere pem credentials on the primary server.

source chuboe.properties
echo HERE:: setting variables
TMP_REMOTE_BACKUP_SERVER=CHANGE_ME # CHANGE_ME to the ip of the primary server
TMP_HOSTNAME=0.0.0.0 # this does not change - name of local machine
TMP_SSH_PEM="" # example: "-i /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/YOUR_PEM_NAME.pem" # CHANGE_ME to point to the idempiere user pem on this server
# If using AWS or a pem key, be sure to copy the pem to the restore computer /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/ directory
TMP_XMX=1G
# make sure to chmod 400 the pem
TMP_SSH_PEM_RSYNC="-e \"ssh $TMP_SSH_PEM\""
# If using AWS or a pem key, be sure to copy the pem to the restore computer /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/ directory
# make sure to chmod 400 the pem

echo HERE:: testing for test server
# check to see if dedicated WEBUI server - else exit
if [[ $CHUBOE_PROP_IS_DEDICATED_WEBUI != "Y" ]]; then
    echo "Not a WEBUI environment - exiting now!" 
    echo "Check chuboe.properties => CHUBOE_PROP_IS_DEDICATED_WEBUI variable."
    exit 1
fi

echo HERE:: stopping idempiere
sudo service idempiere stop

echo HERE:: sync idempiere folder
eval sudo rsync "--exclude "/.hg/" --exclude "/migration/" --exclude "/data/" --exclude "/log/" --delete-excluded -P $TMP_SSH_PEM_RSYNC -a --delete $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:/$CHUBOE_PROP_IDEMPIERE_PATH $CHUBOE_PROP_IDEMPIERE_PATH"

# run console-setup.sh
# NOTE: commented out below assuming configuration (including AppServer IP 0.0.0.0) is the same.
# echo "HERE: Launching console-setup.sh"

#FYI each line represents an input. Each blank line takes the console-setup.sh default.
#HERE are the prompts:
#jdk
#idempiere_home
#keystore_password - if run a second time, the lines beginning with dashes do not get asked again
#- common_name
#- org_unit
#- org
#- local/town
#- state
#- country
#host_name
#app_server_web_port
#app_server_ssl_port
#db_exists
#db_type
#db_server_host
#db_server_port
#db_name
#db_user
#db_password
#db_system_password
#mail_host
#mail_user
#mail_user_password
#mail_admin_email
#save_changes

#not indented because of file input
cd $CHUBOE_PROP_IDEMPIERE_PATH
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER sh console-setup.sh <<!



$TMP_HOSTNAME




$CHUBOE_PROP_DB_HOST



$CHUBOE_PROP_DB_PASSWORD_SU
$CHUBOE_PROP_DB_PASSWORD_SU





!
# end of file input

echo HERE:: update xmx and xms
# update system configuration (like XMX, XMS, etc...)
#sudo sed -i 's/-Xms8G -Xmx8G/-Xms16G -Xmx16G/g' /$CHUBOE_PROP_IDEMPIERE_PATH/idempiere-server.sh
#sudo sed -i 's/-Xms8G -Xmx8G/-Xms16G -Xmx16G/g' /$CHUBOE_PROP_IDEMPIERE_PATH/idempiereEnv.properties
sudo sed -i 's|IDEMPIERE_JAVA_OPTIONS=.*|IDEMPIERE_JAVA_OPTIONS=\"-Xms$TMP_XMX -Xmx$TMP_XMX -DIDEMPIERE_HOME=\$IDEMPIERE_HOME\"|g' /$CHUBOE_PROP_IDEMPIERE_PATH/utils/myEnvironment.sh


echo HERE:: update login screen
# update the login screen to show the desired hostname
find /opt/idempiere-server/ -name version-info.zul |
while read filename
do
    sudo sed -i "s|\${desktop.execution.serverName}|$CHUBOE_PROP_WEBUI_IDENTIFICATION|g" $filename
done


# start idempiere  
echo "HERE:: starting iDempiere"
sudo service idempiere start
