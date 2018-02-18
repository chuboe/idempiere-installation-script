#!/bin/bash
# Created Version 1 and 2 by Sandy Corsillo

######################################
# This file is dangerous. It will overwrite your database.
# This script should only be executed from a development instance - NOT PRODUCTION.
######################################

#Bring chuboe.properties into context
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
CHUBOE_UTIL_HG_PROP="$CHUBOE_UTIL_HG/utils/properties/"
LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_db_restore.log"
ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
LOCALBACKDIR="chuboe_restore"
S3BUCKET=$CHUBOE_PROP_BACKUP_S3_BUCKET
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER

echo LOGFILE=$LOGFILE >> $LOGFILE
echo ADEMROOTDIR="$ADEMROOTDIR" >> $LOGFILE

cd "$ADEMROOTDIR"/utils
echo ademres: ------------------------------------------------------------------- >> $LOGFILE
echo ademres: -------          STARTING iDempiere Daily Restore           ------- >> $LOGFILE
echo ademres: ------------------------------------------------------------------- >> $LOGFILE

if [[ $CHUBOE_PROP_IS_TEST_ENV == "Y" ]]; then
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    echo ademres: -------              This is a Dev Envrionment              ------- >> $LOGFILE
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
else
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    echo ademres: -------            STOPPING Not a Dev Envrionment           ------- >> $LOGFILE
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    exit 1
fi #end if dev environment check

#create a local backup just in case
echo Creating a local backup just in case.
echo NOTE: Ignore errors related to myEnvironment.sav.
cd "$ADEMROOTDIR"/utils
sudo -u $IDEMPIEREUSER ./RUN_DBExport.sh

if sudo service idempiere stop >> $LOGFILE
then
    echo ademres: iDempiere Stopped >> $LOGFILE
    if s3cmd sync --delete-after s3://"$S3BUCKET"/latest/ "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/ >> $LOGFILE
    then
        cd "$ADEMROOTDIR"/data
        sudo rm ExpDat.dmp
        sudo -u $IDEMPIEREUSER jar xf "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/*.jar
        cd "$ADEMROOTDIR"/utils
        echo NOTE: Ignore errors related to myEnvironment.sav.
        if sudo -u $IDEMPIEREUSER ./RUN_DBRestore.sh <<!

!
        then
            if sudo service idempiere start >> $LOGFILE
            then
                echo ademres: iDempiere Started Back Up >> $LOGFILE
            else
                echo ademres: ------------------------------------------------------------------- >> $LOGFILE
                echo ademres: -------         Remote iDempiere Backup FAILED!             ------- >> $LOGFILE
                echo ademres: ------------------------------------------------------------------- >> $LOGFILE
                exit 1
            fi
        else
            echo ademres: ------------------------------------------------------------------- >> $LOGFILE
            echo ademres: -------          Idempiere Restore FAILED!                  ------- >> $LOGFILE
            echo ademres: ------------------------------------------------------------------- >> $LOGFILE
            exit 1
        fi
    else
        echo ademres: ------------------------------------------------------------------- >> $LOGFILE
        echo ademres: -------         iDempiere Sync From Remote S3 FAILED!       ------- >> $LOGFILE
        echo ademres: ------------------------------------------------------------------- >> $LOGFILE
        exit 1
    fi
else
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    echo ademres: -------         iDempiere Stop Service FAILED!              ------- >> $LOGFILE
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    exit 1 
fi
echo ademres: ------------------------------------------------------------------- >> $LOGFILE
echo ademres: -------         COMPLETED iDempiere Daily Restore           ------- >> $LOGFILE
echo ademres: ------------------------------------------------------------------- >> $LOGFILE
exit 0
