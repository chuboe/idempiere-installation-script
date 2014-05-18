#!/bin/bash

# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
# chuboe_upgrade.sh
# 1.0 initial release

# function to help the user better understand how the script works
usage()
{
cat << EOF

usage: $0

This script helps you upgrade your iDempiere server

OPTIONS:
	-h	Help
	-c	Specify connection options
	-m	Specify path to migration scripts
	-u	Upgrade URL
	-r	Do not restart server

Outstanding actions:
* add issues here

EOF
}

LOG_FILE="/log/chuboe_app_upgrade.log"
SERVER_DIR="/opt/idempiere-server"
P2="http://jenkins.idempiere.com/job/iDempiere/ws/buckminster.output/org.adempiere.server_2.0.0-eclipse.feature/site.p2/"
PG_HOST_NORM="host    all             all             127.0.0.1/32            md5"
PG_HOST_TEMP="host    all             all             127.0.0.1/32            trust"
PG_HBA="/etc/postgresql/9.1/main/pg_hba.conf"
SYNC_APP="https://bitbucket.org/CarlosRuiz_globalqss/idempiere-stuff/raw/tip/script_to_sync_db/syncApplied.sh"
ID_DB_NAME="idempiere"
PG_CONNECT="-h localhost"
MIGRATION_DIR=$SERVER_DIR"/chuboe_temp/migration"
MIGRATION_DOWNLOAD="http://jenkins.idempiere.com/job/iDempiereDaily/ws/migration/*zip*/migration.zip"
IS_RESTART_SERVER="Y"
IS_GET_MIGRATION="Y"

# process the specified options
# the colon after the letter specifies there should be text with the option
while getopts "hc:m:u:r" OPTION
do
	case $OPTION in
		h)	usage
			exit 1;;

		c)	#Specify connection options
			PG_CONNECT=$OPTARG;;

		m)	#Specify path to migration scripts
			IS_GET_MIGRATION="N"
			MIGRATION_DIR=$OPTARG;;

		u)	#Upgrade URL
			P2=$OPTARG;;

		r)	#Do not restart server
			IS_RESTART_SERVER="N";;
	esac
done

# show variables to the user (debug)
echo "if you want to find for echoed values, search for HERE:"
echo "HERE: print variables"
echo "LOG_FILE="$LOG_FILE
echo "SERVER_DIR="$SERVER_DIR
echo "P2="$P2
echo "PG_HOST_NORM="$PG_HOST_NORM
echo "PG_HOST_TEMP="$PG_HOST_TEMP
echo "PG_HBA="$PG_HBA
echo "SYNC_APP="$SYNC_APP
echo "ID_DB_NAME="$ID_DB_NAME
echo "PG_CONNECT="$PG_CONNECT
echo "MIGRATION_DIR="$MIGRATION_DIR
echo "MIGRATION_DOWNLOAD="$MIGRATION_DOWNLOAD
echo "IS_RESTART_SERVER="$IS_RESTART_SERVER
echo "IS_GET_MIGRATION="$IS_GET_MIGRATION

# Get migration scripts if none specified
if [[ $IS_GET_MIGRATION == "Y" ]]
then
	# ACTION: Create chuboe_temp directory in main installation script
	cd $SERVER_DIR/chuboe_temp
	# ACTION: check to see if previous migration zip exists, if so delete
	# ACTION: check to see if previous migration directory exists, if so delete
	wget $MIGRATION_DOWNLOAD
	unzip migration.zip
fi #end if IS_GET_MIGRATION = Y

if [[ $IS_RESTART_SERVER == "Y" ]]
then
	sudo service idempiere stop
fi #end if IS_RESTART_SERVER = Y

cd $SERVER_DIR
./update.sh $P2

cd $SERVER_DIR/utils/
sh RUN_DBExport.sh

sudo sed -i 's|$PG_HOST_NORM|$PG_HOST_TEMP|' $PG_HBA
sudo service postgresql restart

cd $SERVER_DIR/chuboe_utils/

# ACTION: see if Carlos recommends a hg pull instead of a wget for syncApplied.sh

# Get Carlos Ruiz syncApplied.sh script
# check to see if syncApplied.sh exists
RESULT=$(ls -l syncApplied.sh | wc -l)
if [ $RESULT -ge 1 ]; then
	echo "HERE: syncApplied.sh already exists"
else
	echo "HERE: syncApplied.sh does not exist"
	echo "getting syncApplied.sh"
	wget $SYNC_APP
	chmod 766 syncApplied.sh
fi #end if syncApplied.sh exists

./syncApplied.sh $ID_DB_NAME "$PG_CONNECT" $MIGRATION_DIR

sudo sed -i 's|$PG_HOST_TEMP|$PG_HOST_NORM|' $PG_HBA
sudo service postgresql restart

if [[ $IS_RESTART_SERVER == "Y" ]]
then
	sudo service idempiere start
fi #end if IS_RESTART_SERVER = Y