#!/bin/bash
# Created Version 1 and 2 by Sandy Corsillo

######################################
# This file is dangerous. It will overwrite your database.
# This script should only be executed from a development instance - NOT PRODUCTION.
# ACTION: update the file to test for the existance of a .chuboe_dev file to confirm this is a dev instance.
# ACTION: consider performing a local backup before restoring just in case someone accidentally performs this task
######################################

CHUBOE_UTIL="/opt/chuboe_utils/"
CHUBOE_UTIL_HG="$CHUBOE_UTIL/idempiere-installation-script/"
CHUBOE_UTIL_HG_PROP="$CHUBOE_UTIL_HG/utils/properties/"
LOGFILE="/log/chuboe_db_restore.log"
ADEMROOTDIR="/opt/idempiere-server"
LOCALBACKDIR="chuboe_restore"
S3BUCKET="iDempiere_backup"
IDEMPIEREUSER="idempiere"

echo LOGFILE="$CHUBOE_UTIL_HG"/"$LOGFILE" >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$CHUBOE_UTIL_HG"/"$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo ademres: -------          STARTING iDempiere Daily Restore           ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"

RESULT=$(ls -l $CHUBOE_UTIL_HG_PROP/CHUBOE_TEST_ENV_YES.txt | wc -l)
if [ $RESULT -ge 1 ]; then
    echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo ademres: -------              This is a Dev Envrionment              ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
else
    echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo ademres: -------            STOPPING Not a Dev Envrionment           ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    exit 1
fi #end if dev environment check

if sudo service idempiere stop >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
then
    echo ademres: iDempiere Stopped >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    if s3cmd sync --delete s3://"$S3BUCKET"/latest/ "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/ >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    then
        cd "$ADEMROOTDIR"/data
        sudo rm ExpDat.dmp
        sudo -u $IDEMPIEREUSER jar xf "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/*.jar
        cd "$ADEMROOTDIR"/utils
        if sudo -u $IDEMPIEREUSER ./RUN_DBRestore.sh <<!

!
        then
            if sudo service idempiere start >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
            then
                echo ademres: iDempiere Started Back Up >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
            else
                echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
                echo ademres: -------         Remote iDempiere Backup FAILED!             ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
                echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
                #sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
                #sudo cp /dev/null /var/log/ex_restore.log
                exit 1
            fi
        else
            echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
            echo ademres: -------          Idempiere Restore FAILED!                  ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
            echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
            #sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
            #sudo cp /dev/null /var/log/ex_restore.log
            exit 1
        fi
    else
        echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
        echo ademres: -------         iDempiere Sync From Remote S3 FAILED!       ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
        echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
        #sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
        #sudo cp /dev/null /var/log/ex_restore.log
        exit 1
    fi
else
    echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo ademres: -------         iDempiere Stop Service FAILED!              ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    #sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
    #sudo cp /dev/null /var/log/ex_restore.log
    exit 1 
fi
echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo ademres: -------         COMPLETED iDempiere Daily Restore           ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
#sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
#sudo cp /dev/null /var/log/ex_restore.log
exit 0
