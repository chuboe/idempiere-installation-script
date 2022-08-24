#!/bin/bash
set -e
# {{{ Version 1 Chuck Boecking - created

# This script uses rsync to restore a sandbox server from a production primary or services server
# This script series assumes that the chuboe installation script was used to install iD on both servers
# This script assumes that you can ssh into the primary server via the idempiere user
# You can use the chuboe_adduser_os.sh script to create idempiere pem credentials on the primary server.
# This differs from chuboe_restore_s3cmd.sh because it also moves binaries.}}}

# {{{ Context
#Bring chuboe.properties into context
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
source $SC_SCRIPTPATH/chuboe.properties

SC_LOGFILE="$SC_SCRIPTPATH/LOGS/$SC_BASENAME."`date +%Y%m%d`_`date +%H%M%S`".log"
SC_ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
SC_IDEMPIERE_OS_USER=$CHUBOE_PROP_IDEMPIERE_OS_USER
SC_UTIL=$CHUBOE_PROP_UTIL_PATH
SC_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
SC_LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
SC_USER=$CHUBOE_PROP_DB_USERNAME

SC_REMOTE_BACKUP_SERVER=CHANGE_ME # CHANGE_ME to the ip of the primary server
SC_HOSTNAME=0.0.0.0 # this does not change - name of local machine
SC_SSH_PEM="" # example: "-i /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/YOUR_PEM_NAME.pem" # CHANGE_ME to point to the idempiere user pem on this server

# If using AWS or a pem key, be sure to copy the pem to the restore computer /home/$CHUBOE_PROP_IDEMPIERE_OS_USER/.ssh/ directory
# make sure to chmod 400 the pem
SC_SSH_PEM_RSYNC="-e \"ssh $SC_SSH_PEM\""
SC_DMS_CONTENT_PATH=/opt/DMS/DMS_Content/
SC_DMS_THUMBNAILS_PATH=/opt/DMS/DMS_Thumbnails/
# }}}

if [ "$TERM" = "screen" ] # {{{ TMUX Check
then
    echo Confirmed inside screen or tmux to preserve session if disconnected.
else
    echo Exiting... not running inside screen or tumx to preserve session if disconnected.
    exit 1
fi #}}}

# {{{ Logging
echo "Be sure to tee to a log file, for example:"
echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
read -p "press Enter to continue, or Ctrl+C to stop" 
#REMEMBER when calling these scripts from other scripts use "echo $'\n' | #####.sh" to bypass read }}}

echo HERE:: testing for test server #{{{
if [[ $CHUBOE_PROP_IS_TEST_ENV != "Y" ]]; then
    echo "Not a test environment - exiting now!"
    echo "Check chuboe.properties => CHUBOE_PROP_IS_TEST_ENV variable."
    exit 1
fi # }}}

echo HERE:: stopping idempiere
sudo service idempiere stop

echo HERE:: starting rsync for idempiere folder
eval sudo rsync "--exclude "/.hg/" --exclude "/migration/" --exclude "/data/" --exclude "/log/" --delete-excluded -P $SC_SSH_PEM_RSYNC -a --delete $SC_IDEMPIERE_OS_USER@$SC_REMOTE_BACKUP_SERVER:/$SC_ADEMROOTDIR $SC_ADEMROOTDIR"

echo HERE:: copying over pg_dump
cd $SC_LOCALBACKDIR
eval sudo rsync "--delete-excluded -P $SC_SSH_PEM_RSYNC -a --delete $SC_IDEMPIERE_OS_USER@$SC_REMOTE_BACKUP_SERVER:/$SC_LOCALBACKDIR/latest/ latest/"

# uncomment below statements to sync DMS folders {{{
# echo HERE:: rsync DMS
# eval sudo rsync "-P $TMP_SSH_PEM_RSYNC -a --delete $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:/$DMS_CONTENT_PATH $DMS_CONTENT_PATH"

# eval sudo rsync "-P $TMP_SSH_PEM_RSYNC -a --delete $CHUBOE_PROP_IDEMPIERE_OS_USER@$TMP_REMOTE_BACKUP_SERVER:/$TMP_DMS_THUMBNAILS_PATH $TMP_DMS_THUMBNAILS_PATH"
# }}}

# {{{ run console-setup.sh
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
# }}} end of file input

echo HERE:: restore database
# restore the database
cd $SC_SCRIPTPATH
echo $'\n' | ./chuboe_restore_local.sh

echo HERE:: update xmx and xms # {{{
# remove any xmx or xms from command line - note that '.' is a single placeholder wildcard
sudo sed -i 's|-Xms.G -Xmx.G||g' /opt/idempiere-server/idempiere-server.sh
# alternatively, you could set the value accordingly to either of the following:
# sudo sed -i 's|-Xms.G -Xmx.G|-Xms2G -Xmx2G|g' /opt/idempiere-server/idempiere-server.sh
# sudo sed -i 's|\$IDEMPIERE_JAVA_OPTIONS \$VMOPTS|\$IDEMPIERE_JAVA_OPTIONS \$VMOPTS -Xmx2048m -Xms2048m|g' /opt/idempiere-server/idempiere-server.sh
# preferred - replace the whole line in myEnvironment.sh - update the values below according to your environment
# sudo sed -i "s|IDEMPIERE_JAVA_OPTIONS=.*|IDEMPIERE_JAVA_OPTIONS=\"-Xms2G -Xmx2G -DIDEMPIERE_HOME=\$IDEMPIERE_HOME\"|g" /opt/idempiere-server/utils/myEnvironment.sh
#}}}

echo HERE:: run restore script
# update the database with test/sand settings
cd $SC_SCRIPTPATH
./chuboe_restore_sandbox_sql.sh

# start idempiere
echo "HERE:: starting iDempiere"
sudo service idempiere restart
