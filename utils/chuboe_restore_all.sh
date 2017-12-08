#!/bin/bash
# Version 1 Chuck Boecking - created

# This script belongs to a collection of scripts that copies iD to a new instance.
# This script restores iDempiere from a backup.
# This differs from chuboe_restore_s3cmd.sh because it also moves binaries.
# This script series assumes that the chuboe installation script was used to install iD on both servers
# Be aware that you need about 10GB of free space on the drive for the below to succeed.

source chuboe.properties
TMP_BACKUP_FILE_NAME=id.tar.gz
TMP_BACKUP_PATH=/tmp/id_back/
TMP_RESTORE_PATH=/tmp/id_restore_new/
TMP_BACKUP_PATH_DIR=$TMP_BACKUP_PATH/dirs/
TMP_RESTORE_PATH_DIR=$TMP_RESTORE_PATH/dirs/
TMP_REMOTE_BACKUP_SERVER=localhost
TMP_REMOTE_BACKUP_USER=ubuntu
TMP_HOSTNAME=$(hostname)

# check to see if test server - else exit
if [[ $CHUBOE_PROP_IS_TEST_ENV != "Y" ]]; then
    echo "Not a test environment - exiting now!" 
    echo "Check chuboe.properties => CHUBOE_PROP_IS_TEST_ENV variable."
    exit 1
fi

# remove previous backup and restore folders
echo "HERE: remove previous old backups from $TMP_BACKUP_PATH."
sudo rm -r $TMP_BACKUP_PATH
echo "HERE: remove previous restore files and folders from $TMP_RESTORE_PATH."
sudo rm -r $TMP_RESTORE_PATH

# create a database backup that captures the current state of the machine
echo "HERE: create backup of db."
cd $CHUBOE_PROP_IDEMPIERE_PATH/utils/
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER ./RUN_DBExport.sh

# create temp backup directory and copy all files
echo "HERE: cp current iD directory to $TMP_BACKUP_PATH folder."
sudo mkdir -p $TMP_BACKUP_PATH_DIR
sudo chown $CHUBOE_PROP_IDEMPIERE_OS_USER:$CHUBOE_PROP_IDEMPIERE_OS_USERGROUP $TMP_BACKUP_PATH -R
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER cp $CHUBOE_PROP_IDEMPIERE_PATH $TMP_BACKUP_PATH_DIR -R

# create tar backup of old iDempiere instance.
echo "HERE: create tar file of backup iD folder." 
echo "Note: this file exists in the /tmp folder. It will be deleted during the next restart."
cd $TMP_BACKUP_PATH
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER tar cvfz $TMP_BACKUP_FILE_NAME dirs/
sudo rm -r $TMP_BACKUP_PATH_DIR

# stop idempiere
sudo service idempiere stop

# create temp restore directory
sudo mkdir -p $TMP_RESTORE_PATH
sudo chown $CHUBOE_PROP_IDEMPIERE_OS_USER:$CHUBOE_PROP_IDEMPIERE_OS_USERGROUP $TMP_RESTORE_PATH -R

# remove current idempiere installation
sudo rm $CHUBOE_PROP_IDEMPIERE_PATH  -r

# uncomment below rm statements to remove DMS folders
# sudo rm /opt/DMS_Content/ -r
# sudo rm /opt/DMS_Thumbnails/ -r

# copy back up file from another location
echo "HERE: copying remote backup file ($TMP_REMOTE_BACKUP_SERVER:$TMP_BACKUP_PATH) to $TMP_RESTORE_PATH"
cd $TMP_RESTORE_PATH
# note: you can replace the below scp command with a wget or curl if the file is coming from a web server or a local directory
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER scp $TMP_REMOTE_BACKUP_USER@$TMP_REMOTE_BACKUP_SERVER:$TMP_BACKUP_PATH/$TMP_BACKUP_FILE_NAME $TMP_RESTORE_PATH/.

# untar back up file
cd $TMP_RESTORE_PATH
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER tar zxvf $TMP_BACKUP_FILE_NAME

# replace files
sudo mv $TMP_RESTORE_PATH_DIR/idempiere-server/ /opt/

# uncomment below mv statements to replace DMS folders
# sudo mv $TMP_RESTORE_PATH_DIR/DMS_Content/ /opt/
# sudo mv $TMP_RESTORE_PATH_DIR/DMS_Thumbnails/ /opt/

# run console-setup.sh
echo "HERE: Launching console-setup.sh"
cd $CHUBOE_PROP_IDEMPIERE_PATH

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
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER sh console-setup.sh <<!



$TMP_HOSTNAME




$CHUBOE_PROP_DB_HOST



$CHUBOE_PROP_DB_PASSWORD_SU
$CHUBOE_PROP_DB_PASSWORD_SU





!
# end of file input

# restore the database
cd $CHUBOE_PROP_IDEMPIERE_PATH/utils/
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER ./RUN_DBRestore.sh <<!

!

# update SQL in restored database that might be specific to this server
# update system logos - you can also set them to something else like 'http://cdn6.bigcommerce.com/s-d8bzk61/images/stencil/200x100/products/1988/2724/safetyglassesusa_2267_30575914__24175.1448998397.jpg'
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update AD_SysConfig set isactive = 'N' where upper(name) like 'ZK_LOGO%'"
# disable email in test/sandbox system
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update ad_client set smtphost = '', issmtpauthorization = 'N', issecuresmtp = 'N', smtpport = null, requestuser = '', requestemail = ''"

# start idempiere  
echo "HERE: starting iDempiere"
sudo service idempiere start
