#!/bin/bash
# Version 1 Chuck Boecking - created

# This script uses rsync to restore a sandbox server from a production primary or services server
# This script series assumes that the chuboe installation script was used to install iD on both servers
# This script assumes that you can ssh into the primary server via the idempiere user
# You can use the chuboe_adduser_os.sh script to create idempiere pem credentials on the primary server.
# This differs from chuboe_restore_s3cmd.sh because it also moves binaries.

if [ "$TERM" = "screen" ]
then
    echo Confirmed inside screen or tmux to preserve session if disconnected.
else
    echo Exiting... not running inside screen or tumx to preserve session if disconnected.
    exit 1
fi

source chuboe.properties
echo HERE:: setting variables 
TMP_REMOTE_BACKUP_SERVER=CHANGE_ME # CHANGE_ME to the ip of the primary server
TMP_HOSTNAME=0.0.0.0 # this does not change - name of local machine
TMP_SSH_PEM="" # example: "-i /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/YOUR_PEM_NAME.pem" # CHANGE_ME to point to the idempiere user pem on this server
# If using AWS or a pem key, be sure to copy the pem to the restore computer /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/ directory
# make sure to chmod 400 the pem
TMP_SSH_PEM_RSYNC="-e \"ssh $TMP_SSH_PEM\""
TMP_DMS_CONTENT_PATH=/opt/DMS/DMS_Content/
TMP_DMS_THUMBNAILS_PATH=/opt/DMS/DMS_Thumbnails/

echo HERE:: testing for test server 
# check to see if test server - else exit
if [[ $CHUBOE_PROP_IS_TEST_ENV != "Y" ]]; then
    echo "Not a test environment - exiting now!"
    echo "Check chuboe.properties => CHUBOE_PROP_IS_TEST_ENV variable."
    exit 1
fi

echo HERE:: stopping idempiere
sudo service idempiere stop

echo HERE:: starting rsync for idempiere folder
eval sudo rsync "--exclude "/.hg/" --exclude "/migration/" --exclude "/data/" --exclude "/log/" --delete-excluded -P $TMP_SSH_PEM_RSYNC -a --delete $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:/$CHUBOE_PROP_IDEMPIERE_PATH $CHUBOE_PROP_IDEMPIERE_PATH"

echo HERE:: copying over ExpDat.dmp
# copy ExpDat.dmp goes here
cd $CHUBOE_PROP_IDEMPIERE_PATH/
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER mkdir -p data
cd data/
echo sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER scp $TMP_SSH_PEM $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:$CHUBOE_PROP_IDEMPIERE_PATH/data/ExpDat.dmp .
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER scp $TMP_SSH_PEM $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:$CHUBOE_PROP_IDEMPIERE_PATH/data/ExpDat.dmp .

# uncomment below statements to sync DMS folders
# echo HERE:: rsync DMS
# eval sudo rsync "-P $TMP_SSH_PEM_RSYNC -a --delete $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:/$DMS_CONTENT_PATH $DMS_CONTENT_PATH"

# eval sudo rsync "-P $TMP_SSH_PEM_RSYNC -a --delete $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:/$TMP_DMS_THUMBNAILS_PATH $TMP_DMS_THUMBNAILS_PATH"

# run console-setup.sh
echo "HERE:: Launching console-setup.sh"
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


N

$CHUBOE_PROP_DB_HOST



$CHUBOE_PROP_DB_PASSWORD_SU
$CHUBOE_PROP_DB_PASSWORD_SU





!
# end of file input

echo HERE:: restore database
# restore the database
cd $CHUBOE_PROP_IDEMPIERE_PATH/utils/
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER ./RUN_DBRestore.sh <<!

!

echo HERE:: update xmx and xms
# note that regex '.' is a single placeholder wildcard
# note that regex '\S*' is an end-of-word wildcard
# sudo sed -i "s|IDEMPIERE_JAVA_OPTIONS=.*|IDEMPIERE_JAVA_OPTIONS=\"-Xms2G -Xmx2G -DIDEMPIERE_HOME=\$IDEMPIERE_HOME\"|g" /opt/idempiere-server/utils/myEnvironment.sh
sudo sed -i "s|\bXmx\S*|Xmx1G|g" /opt/idempiere-server/utils/myEnvironment.sh
sudo sed -i "s|\bXms\S*|Xms1G|g" /opt/idempiere-server/utils/myEnvironment.sh

echo HERE:: run restore script
# update the database with test/sand settings
cd $CHUBOE_PROP_UTIL_HG_UTIL_PATH
./chuboe_restore_sandbox_sql.sh

# start idempiere
echo "HERE:: starting iDempiere"
sudo service idempiere start
