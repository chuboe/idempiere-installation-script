#!/bin/bash

#restore from backup

#https://www.postgresql.org/docs/12/backup-file.html

START_TIME=`date +%s`
echo Start time = $START_TIME

source /opt/chuboe/idempiere-installation-script/utils/chuboe.properties

echo stopping idempiere
sudo service idempiere stop

echo sleeping for 20 to allow idempiere to stop
sleep 20

echo stopping postgresql
sudo service postgresql stop

SERVICE=idempiere
if (( $(ps -ef | grep -v grep | grep $SERVICE | wc -l) > 0 ))
then
	echo "Exiting now. $SERVICE is running!!!"
	exit 1
else
	echo $SERVICE is stopped
fi

SERVICE=postgresql
if (( $(ps -ef | grep -v grep | grep $SERVICE | wc -l) > 0 ))
then
	echo "Exiting now. $SERVICE is running!!!"
	exit 1
else
	echo $SERVICE is stopped
fi

PIT_ID=/opt/pit-id/
PIT_DB=/opt/pit-db/

ID_SERVER=/opt/idempiere-server/
DB_SERVER=/var/lib/postgresql/$CHUBOE_PROP_DB_VERSION/main/

#sudo rm -r $PIT_ID
#sudo rm -r $PIT_DB
#
#sudo mkdir $PIT_ID
#sudo mkdir $PIT_DB
#
#sudo chown -R idempiere:idempiere $PIT_ID
#sudo chown -R postgres:postgres $PIT_DB

echo HERE: Make sure proper directories exist before starting...
DIR=$PIT_ID
if [ -d "$DIR"  ]; then
        echo diretory $DIR exists. Continue...
    else
        echo STOPPING... diretory $DIR does not exist.
        exit 1
fi

DIR=$PIT_DB
if [ -d "$DIR"  ]; then
        echo diretory $DIR exists. Continue...
    else
        echo STOPPING... diretory $DIR does not exist.
        exit 1
fi

sudo -u idempiere rsync -av --delete $PIT_ID/ $ID_SERVER/
sudo -u postgres rsync -av --delete $PIT_DB/ $DB_SERVER/

#the following is for copying an existing backup from a remove sandbox/uat
#sudo -u idempiere rsync -av --exclude "/data/" --delete chuboe@REMOTE_SERVER_HERE:/opt/idempiere-server/ $PIT_ID/

echo starting postgresql
sudo service postgresql start

echo starting idempiere
sudo service idempiere start

echo Make sure variables are set correctly for this server
cd /opt/chuboe/idempiere-installation-script/utils/
./chuboe_restore_sandbox_sql.sh

END_TIME=`date +%s`
echo End Time = $END_TIME

RUNTIME=$((END_TIME-START_TIME))
echo Run time = $RUNTIME

echo Finished!!!
