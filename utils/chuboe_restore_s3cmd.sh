#!/bin/bash
# Created Version 1 and 2 by Sandy Corsillo

######################################
# This file is dangerous. It will overwrite your database.
# This script should only be executed from a development instance - NOT PRODUCTION.
# ACTION: update the file to test for the existance of a .chuboe_dev file to confirm this is a dev instance.
# ACTION: consider performing a local backup before restoring just in case someone accidentally performs this task
######################################

LOGFILE="/log/chuboe_db_export.log"
ADEMROOTDIR="/opt/idempiere-server"
LOCALBACKDIR="chuboe_restore"
S3BUCKET="iDempiere_backup"

echo LOGFILE="$ADEMROOTDIR"/"$LOGFILE" >> "$ADEMROOTDIR"/"$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$ADEMROOTDIR"/"$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo ademres: -------          STARTING iDempiere Daily Restore           ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
if sudo service idempiere stop >> "$ADEMROOTDIR"/"$LOGFILE"
then
    echo ademres: Idempiere Stopped >> "$ADEMROOTDIR"/"$LOGFILE"
    if s3cmd sync --delete s3://iDempiere_backup2/latest/ "$ADEMROOTDIR"/data/ex_restore_backups/ >> "$ADEMROOTDIR"/"$LOGFILE"
    then
        cd "$ADEMROOTDIR"/data
        rm ExpDat.dmp
        jar xf "$ADEMROOTDIR"/data/ex_restore_backups/*.jar
        cd "$ADEMROOTDIR"/utils
        if ./RUN_DBRestore.sh #>> "$ADEMROOTDIR"/"$LOGFILE"
        then
            if sudo service idempiere start >> "$ADEMROOTDIR"/"$LOGFILE"
            then
                echo ademres: Idempiere Started Back Up >> "$ADEMROOTDIR"/"$LOGFILE"
            else
                echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
                echo ademres: -------         Remote iDempiere Backup FAILED!             ------- >> "$ADEMROOTDIR"/"$LOGFILE"
                echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
                sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
                sudo cp /dev/null /var/log/ex_restore.log
                exit 1
            fi
        else
            echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
            echo ademres: -------          Idempiere Restore FAILED!                  ------- >> "$ADEMROOTDIR"/"$LOGFILE"
            echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
            sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
            sudo cp /dev/null /var/log/ex_restore.log
            exit 1
        fi
    else
        echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo ademres: -------         iDempiere Sync From Remote S3 FAILED!       ------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
        sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
        sudo cp /dev/null /var/log/ex_restore.log
        exit 1
    fi
else
    echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo ademres: -------         iDempiere Stop Service FAILED!              ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
    sudo cp /dev/null /var/log/ex_restore.log
    exit 1 
fi
echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo ademres: -------         COMPLETED iDempiere Daily Restore           ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
sudo cp /dev/null /var/log/ex_restore.log
exit 0