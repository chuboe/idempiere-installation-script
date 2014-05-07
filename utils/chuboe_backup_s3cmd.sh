#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
LOGFILE="/var/log/chuboe_db_export.log"
ADEMROOTDIR="/opt/idempiere-server"
LOCALBACKDIR="ex_backups"
S3BUCKET="iDempiere_backup"

echo LOGFILE="$LOGFILE" >> "$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
echo edembak: -------          STARTING iDempiere Daily Backup            ------- >> "$LOGFILE"
echo adembak: ------------------------------------------------------------------- >> "$LOGFILE"
echo adembak: Executing RUN_DBExport.sh local backup utility. >> "$LOGFILE"
if "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$LOGFILE"
mv "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$ADEMROOTDIR"/data/"$LOCALBACKDIR"/
then
    echo adembak: Local Backup Succeeded.  Copying to cloudshare server. >> "$LOGFILE"
    if s3cmd sync "$ADEMROOTDIR"/data/"$LOCALBACKDIR"/ s3://"$S3BUCKET"/
       s3cmd sync --delete "$ADEMROOTDIR"/data/"$LOCALBACKDIR"/ s3://"$S3BUCKET"/latest/
    then
        echo adembak: Copy of backup file succeeded.  Deleting local copy. >> "$LOGFILE"
        cd "$ADEMROOTDIR"/data/"$LOCALBACKDIR"
        rm "$ADEMROOTDIR"/data/"$LOCALBACKDIR"/ExpDat????????_??????.jar >> "$LOGFILE"
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
