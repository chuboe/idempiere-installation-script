#!/bin/bash
# Created Version 1 and 2 by Sandy Corsillo

######################################
# This file is dangerous. It will overwrite your database.
# This script should only be executed from a development instance - NOT PRODUCTION.
# ACTION: update the file to test for the existance of a .chuboe_dev file to confirm this is a dev instance.
# ACTION: consider performing a local backup before restoring just in case someone accidentally performs this task
######################################

LOGFILE="/var/log/ex_restore.log"
ADEMROOTDIR="/opt/idempiere-server"

echo LOGFILE="$LOGFILE" >> "$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
echo ademres: -------          STARTING iDempiere Daily Restore           ------- >> "$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
if sudo service idempiere stop >> "$LOGFILE"
then
    echo ademres: Idempiere Stopped >> "$LOGFILE"
    if s3cmd sync --delete s3://iDempiere_backup2/latest/ "$ADEMROOTDIR"/data/ex_restore_backups/ >> "$LOGFILE"
    then
        cd "$ADEMROOTDIR"/data
        rm ExpDat.dmp
        jar xf "$ADEMROOTDIR"/data/ex_restore_backups/*.jar
        cd "$ADEMROOTDIR"/utils
        if ./RUN_DBRestore.sh #>> "$LOGFILE"
        then
            if sudo service idempiere start >> "$LOGFILE"
            then
                echo ademres: Idempiere Started Back Up >> "$LOGFILE"
            else
                echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
                echo ademres: -------         Remote iDempiere Backup FAILED!             ------- >> "$LOGFILE"
                echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
                sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
                sudo cp /dev/null /var/log/ex_restore.log
                exit 1
            fi
        else
            echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
            echo ademres: -------          Idempiere Restore FAILED!                  ------- >> "$LOGFILE"
            echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
            sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
            sudo cp /dev/null /var/log/ex_restore.log
            exit 1
        fi
    else
        echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
        echo ademres: -------         iDempiere Sync From Remote S3 FAILED!       ------- >> "$LOGFILE"
        echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
        sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
        sudo cp /dev/null /var/log/ex_restore.log
        exit 1
    fi
else
    echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
    echo ademres: -------         iDempiere Stop Service FAILED!              ------- >> "$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
    sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
    sudo cp /dev/null /var/log/ex_restore.log
    exit 1 
fi
echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
echo ademres: -------         COMPLETED iDempiere Daily Restore           ------- >> "$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$LOGFILE"
sudo cp /var/log/ex_restore.log /var/log/ex_restore_logs/ex_restore_"$(date +'%d_%m_%Y')".log
sudo cp /dev/null /var/log/ex_restore.log
exit 0