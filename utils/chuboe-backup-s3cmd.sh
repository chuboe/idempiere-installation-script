#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
LOGFILE="/var/log/chuboe_db_export.log"
ADEMROOTDIR="/opt/idempiere-server"

echo LOGFILE="$LOGFILE" >> "$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
echo edembak: -------          STARTING iDempiere Daily Backup            ------- >> "$LOGFILE"
echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
echo adembak: Executing RUN_DBExport.sh local backup utility. >> "$LOGFILE"
if "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$LOGFILE"
mv "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$ADEMROOTDIR"/data/ex_backups/
then
    echo adembak: Local Backup Succeeded.  Copying to cloudshare server. >> "$LOGFILE"
    if s3cmd sync "$ADEMROOTDIR"/data/ex_backups/ s3://iDempiere_backup2/
       s3cmd sync --delete "$ADEMROOTDIR"/data/ex_backups/ s3://iDempiere_backup2/latest/
    then
        echo adembak: Copy of backup file succeeded.  Deleting local copy. >> "$LOGFILE"
        cd "$ADEMROOTDIR"/data/ex_backups
        rm "$ADEMROOTDIR"/data/ex_backups/ExpDat????????_??????.jar >> "$LOGFILE"
        echo adembak: Local copy deleted. >> "$LOGFILE"
    else
        echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
        echo adembak: -------         Remote iDempiere Backup FAILED!             ------- >> "$LOGFILE"
        echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
        echo . 
        exit 1
    fi
else
    echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
    echo adembak: -------          Local iDempiere Backup FAILED!             ------- >> "$LOGFILE"
    echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
    echo  .
    exit 1
fi
echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
echo edembak: -------         COMPLETED iDempiere Daily Backup            ------- >> "$LOGFILE"
echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
echo .
exit 0