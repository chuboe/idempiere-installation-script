#!/bin/bash
# Version 1 Chuck Boecking - created

# This script belongs to a collection of scripts that copies iD to a new instance.
# This script restores a iDempiere WEBUI from a primary server (services server).
# This script series assumes that the chuboe installation script was used to install iD on both servers
# Be aware that you need about 10GB of free space on the drive for the below to succeed.

source chuboe.properties
TMP_BACKUP_FILE_NAME=id.tar.gz
TMP_BACKUP_PATH=/tmp/id_back/
TMP_RESTORE_PATH=/tmp/id_restore_new/
TMP_RESTORE_PATH_DIR=$TMP_RESTORE_PATH/dirs/
TMP_REMOTE_BACKUP_SERVER=localhost
TMP_REMOTE_BACKUP_USER=ubuntu
TMP_HOSTNAME=$(hostname)
TMP_SSH_PEM="" # example: " -i /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/YOUR_PEM_NAME.pem"
# If using AWS or a pem key, be sure to copy the pem to the restore computer /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/ directory
# make sure to chmod 400 the pem

# check to see if dedicated WEBUI server - else exit
if [[ $CHUBOE_PROP_IS_DEDICATED_WEBUI != "Y" ]]; then
    echo "Not a WEBUI environment - exiting now!" 
    echo "Check chuboe.properties => CHUBOE_PROP_IS_DEDICATED_WEBUI variable."
    exit 1
fi

# remove previous restore folders
echo "HERE: remove previous restore files and folders from $TMP_RESTORE_PATH."
sudo rm -r $TMP_RESTORE_PATH

# stop idempiere
sudo service idempiere stop

# create temp restore directory
sudo mkdir -p $TMP_RESTORE_PATH
sudo chown $CHUBOE_PROP_IDEMPIERE_OS_USER:$CHUBOE_PROP_IDEMPIERE_OS_USER $TMP_RESTORE_PATH -R

# remove current idempiere installation
sudo rm $CHUBOE_PROP_IDEMPIERE_PATH  -r

# uncomment below rm statements to remove DMS folders
# sudo rm /opt/DMS_Content/ -r
# sudo rm /opt/DMS_Thumbnails/ -r

# copy back up file from another location
echo "HERE: copying remote backup file ($TMP_REMOTE_BACKUP_SERVER:$TMP_BACKUP_PATH) to $TMP_RESTORE_PATH"
cd $TMP_RESTORE_PATH
# note: you can replace the below scp command with a wget or curl if the file is coming from a web server or a local directory
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER scp $TMP_SSH_PEM $TMP_REMOTE_BACKUP_USER@$TMP_REMOTE_BACKUP_SERVER:$TMP_BACKUP_PATH/$TMP_BACKUP_FILE_NAME $TMP_RESTORE_PATH/.


# untar back up file
cd $TMP_RESTORE_PATH
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER tar zxvf $TMP_BACKUP_FILE_NAME

# replace files
sudo mv $TMP_RESTORE_PATH_DIR/idempiere-server/ /opt/

# run console-setup.sh
# NOTE: commented out below assuming configuration (including AppServer IP 0.0.0.0) is the same.
# echo "HERE: Launching console-setup.sh"
# cd $CHUBOE_PROP_IDEMPIERE_PATH

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

#not indented because of file input - uncomment the below if needed
#sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER sh console-setup.sh <<!
#
#
#
#$TMP_HOSTNAME
#
#
#
#
#$CHUBOE_PROP_DB_HOST
#
#
#
#$CHUBOE_PROP_DB_PASSWORD_SU
#$CHUBOE_PROP_DB_PASSWORD_SU
#
#
#
#
#
#!
# end of file input - uncomment the above if needed

# update system configuration (like XMX, XMS, etc...)
sudo sed -i 's/-Xms8G -Xmx8G/-Xms16G -Xmx16G/g' /$CHUBOE_PROP_IDEMPIERE_PATH/idempiere-server.sh
sudo sed -i 's/-Xms8G -Xmx8G/-Xms16G -Xmx16G/g' /$CHUBOE_PROP_IDEMPIERE_PATH/idempiereEnv.properties
VER_INFO_ZUL=$(find /opt/idempiere-server/ -name version-info.zul)
echo $VER_INFO_ZUL
echo "Update this file with WEBUI version number to help identify which server you are using behind the load balancer."

# start idempiere  
echo "HERE: starting iDempiere"
sudo service idempiere start
