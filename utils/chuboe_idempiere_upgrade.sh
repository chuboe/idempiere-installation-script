#!/bin/bash

# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
# chuboe_idempiere_upgrade.sh
# 1.0 initial release

# NOTE: be aware that this script does not make a backup of the /opt/idempiere-server directory. 
# If the upgrade goes badly, you will need to have a way to restore your previous directory.
# Said another way, always perform this upgrade on a test server before executing on a production server.

# function to help the user better understand how the script works
usage()
{
cat << EOF

usage: $0

This script helps you upgrade your iDempiere server

OPTIONS:
	-h	Help
	-c	Specify connection options
	-m	Specify FILE path to migration scripts
	-M	Specify URL to migration scripts
	-u	Upgrade URL to p2 directory
	-r	Do not restart server
	-s	Skip iDempiere binary upgrade
	-p	Create a pristine copy of the database backup
	-b	No DB Backup

Outstanding actions:
* check that a .hg file exists. If no, exit. They should have a backup to the binaries first.

EOF
}

#Bring in chuboe.properties into context
source chuboe.properties

SERVER_DIR=$CHUBOE_PROP_IDEMPIERE_PATH
CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
ID_DB_NAME=$CHUBOE_PROP_DB_NAME
PG_CONNECT="NONE"
MIGRATION_DIR=$CHUBOE_UTIL_HG"/chuboe_temp/migration"
JENKINSPROJECT=$CHUBOE_PROP_JENKINS_PROJECT
JENKINSURL=$CHUBOE_PROP_JENKINS_URL
IDEMPIERE_VERSION=$CHUBOE_PROP_IDEMPIERE_VERSION
IS_RESTART_SERVER="Y"
IS_GET_MIGRATION="Y"
IS_SKIP_BIN_UPGRADE="N"
IS_CREATE_PRISTINE="N"
IS_DB_BACKUP="Y"
MIGRATION_DOWNLOAD="$CHUBOE_PROP_JENKINS_AUTHCOMMAND $CHUBOE_PROP_JENKINS_URL/job/$JENKINSPROJECT/ws/${CHUBOE_PROP_JENKINS_BUILD_NUMBER}/migration/*zip*/migration.zip"
P2="$CHUBOE_PROP_JENKINS_URL/job/$JENKINSPROJECT/ws/${CHUBOE_PROP_JENKINS_BUILD_NUMBER}/buckminster.output/org.adempiere.server_"$IDEMPIERE_VERSION".0-eclipse.feature/site.p2/*zip*/site.p2.zip"
JENKINS_AUTHCOMMAND=$CHUBOE_PROP_JENKINS_AUTHCOMMAND

# process the specified options
# the colon after the letter specifies there should be text with the option
while getopts "hc:m:M:u:rspb" OPTION
do
	case $OPTION in
		h)	usage
			exit 1;;

		c)	#Specify connection options
			PG_CONNECT="-h "$OPTARG;;

		m)	#Specify FILE path to unzipped migration scripts
			IS_GET_MIGRATION="N"
			MIGRATION_DIR=$OPTARG;;

		M)	#Specify URL to migration scripts zip
			MIGRATION_DOWNLOAD=$OPTARG;;

		u)	#Upgrade URL to p2
			P2=$OPTARG;;

		r)	#Do not restart server
			IS_RESTART_SERVER="N";;

		s)	#Do not upgrade binaries
			IS_RESTART_SERVER="N"
			IS_SKIP_BIN_UPGRADE="Y";;

		p)	#create pristine copy
			IS_CREATE_PRISTINE="Y";;

		b)	#No DB backup
			IS_DB_BACKUP="N";;
	esac
done

echo "Do backupDB "$IS_DB_BACKUP

if [[ $PG_CONNECT == "NONE" ]]
then
	PG_CONNECT="-h $CHUBOE_PROP_DB_HOST"
fi

IDEMPIERESOURCEPATHDETAIL="$JENKINSURL/job/$JENKINSPROJECT/ws/${CHUBOE_PROP_JENKINS_BUILD_NUMBER}/changes"

# show variables to the user (debug)
echo "if you want to find for echoed values, search for HERE:"
echo "HERE: print variables"
echo "SERVER_DIR="$SERVER_DIR
echo "P2="$P2
echo "ID_DB_NAME="$ID_DB_NAME
echo "PG_CONNECT="$PG_CONNECT
echo "MIGRATION_DIR="$MIGRATION_DIR
echo "MIGRATION_DOWNLOAD="$MIGRATION_DOWNLOAD
echo "IS_RESTART_SERVER="$IS_RESTART_SERVER
echo "IS_GET_MIGRATION="$IS_GET_MIGRATION
echo "IS_SKIP_BIN_UPGRADE="$IS_SKIP_BIN_UPGRADE
echo "JENKINSPROJECT="$JENKINSPROJECT
echo "IDEMPIERE_VERSION="$IDEMPIERE_VERSION
echo "CHUBOE_UTIL="$CHUBOE_UTIL

# Get migration scripts from daily build if none specified
if [[ $IS_GET_MIGRATION == "Y" ]]
then
	cd $CHUBOE_UTIL_HG/chuboe_temp
	RESULT=$(ls -l migration.zip | wc -l)
	if [ $RESULT -ge 1 ]; then
		echo "HERE: migration.zip already exists"
		sudo rm -r migration*
	fi #end if migration.zip exists

    # preprocess the URL to ensure no double forward slash exists except for ://
    # remove double slashes = sed s#//*#/#g
    # add back :// = sed s#:/#://#g
    MIGRATION_DOWNLOAD=$(echo $MIGRATION_DOWNLOAD | sed 's|//*|/|g' | sed 's|:/|://|g')
    echo "MIGRATION_DOWNLOAD="$MIGRATION_DOWNLOAD
	
    wget $JENKINS_AUTHCOMMAND $MIGRATION_DOWNLOAD
    unzip migration.zip
fi #end if IS_GET_MIGRATION = Y

if [[ $IS_RESTART_SERVER == "Y" ]]
then
	sudo service idempiere stop
fi #end if IS_RESTART_SERVER = Y

if [[ $IS_SKIP_BIN_UPGRADE == "N" ]]
then
    # create a backup of the iDempiere folder before the upgrade
    cd $CHUBOE_UTIL_HG/utils/
    ./chuboe_hg_bindir.sh
	
	cd $CHUBOE_UTIL
	sudo rm -r site.p2*

    # preprocess the URL to ensure no double forward slash exists except for ://
    # remove double slashes = sed s#//*#/#g
    # add back :// = sed s#:/#://#g
    P2_DOWNLOAD=$(echo $P2 | sed 's|//*|/|g' | sed 's|:/|://|g')
    echo "P2_DOWNLOAD="$P2_DOWNLOAD
	
	wget $JENKINS_AUTHCOMMAND $P2_DOWNLOAD
	unzip site.p2.zip
    # update iDempiere binaries
	cd $SERVER_DIR
	sudo -u $IDEMPIEREUSER ./update.sh file://$CHUBOE_UTIL/site.p2/

    # create a backup of the binary directory after the upgrade
    # In case you want to revert to a previous version
    # Step 1: look at the log to determine the changeset you wish to use
    ##  hg log
    # Step 2: issue command to set the previous changeset to the current head/tip (without creating multiple heads)
    ## hg revert --all --rev PUT_OLD/PREVIOUS_CHANGESET_HERE
    # Step 3: commit your changes
    ## hg commit -m "text to remind yourself what you did. Include old and new changeset details"
    cd $CHUBOE_UTIL_HG/utils/
    ./chuboe_hg_bindir.sh

fi #end if IS_SKIP_BIN_UPGRADE = N

if [[ $IS_DB_BACKUP == "Y" ]]
then

	# create a database backup just in case things go badly
	cd $SERVER_DIR/utils/
	echo NOTE: Ignore errors related to myEnvironment.sav
	sudo -u $IDEMPIEREUSER ./RUN_DBExport.sh

fi #end of backup

cd $CHUBOE_UTIL_HG/utils/

# run upgrade db script
./syncApplied.sh $MIGRATION_DIR

# get upgrade details (like build number)
TEMP_NOW=$(date +"%Y%m%d_%H-%M-%S")
sudo wget $JENKINS_AUTHCOMMAND $IDEMPIERESOURCEPATHDETAIL -P $SERVER_DIR -O $SERVER_DIR\iDempiere_Build_Details_"$TEMP_NOW".html

if [[ $IS_CREATE_PRISTINE == "Y" ]]
then
	# create a database backup after upgrade for future reference
	cd $SERVER_DIR/utils/
	sudo -u $IDEMPIEREUSER ./RUN_DBExport.sh
	cd $SERVER_DIR/data/
	sudo -u $IDEMPIEREUSER cp ExpDat.dmp ExpDat_pristine.dmp
fi #end if IS_CREATE_PRISTINE = Y

if [[ $IS_RESTART_SERVER == "Y" ]]
then
	sudo service idempiere start
fi #end if IS_RESTART_SERVER = Y
