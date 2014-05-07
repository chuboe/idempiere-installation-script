#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
# Version 3 Chuck Boecking - added more variables
LOGFILE="/log/chuboe_db_export.log"
ADEMROOTDIR="/opt/idempiere-server"
LOCALBACKDIR="backup"
S3BUCKET="iDempiere_backup"

echo LOGFILE="$ADEMROOTDIR"/"$LOGFILE" >> "$ADEMROOTDIR"/"$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$ADEMROOTDIR"/"$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo edembak: -------          STARTING iDempiere Daily Backup            ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo adembak: Executing RUN_DBExport.sh local backup utility. >> "$ADEMROOTDIR"/"$LOGFILE"
if "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$ADEMROOTDIR"/"$LOGFILE"
mv "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$ADEMROOTDIR"/"$LOCALBACKDIR"/
then
    echo adembak: Local Backup Succeeded.  Copying to S3 bucket. >> "$ADEMROOTDIR"/"$LOGFILE"
    if s3cmd sync "$ADEMROOTDIR"/"$LOCALBACKDIR"/ s3://"$S3BUCKET"/
       s3cmd sync --delete "$ADEMROOTDIR"/"$LOCALBACKDIR"/ s3://"$S3BUCKET"/latest/
    then
        echo adembak: Copy of backup file succeeded.  Deleting local copy. >> "$ADEMROOTDIR"/"$LOGFILE"
        cd "$ADEMROOTDIR"/"$LOCALBACKDIR"
        rm "$ADEMROOTDIR"/"$LOCALBACKDIR"/ExpDat????????_??????.jar >> "$ADEMROOTDIR"/"$LOGFILE"
        echo adembak: Local copy deleted. >> "$ADEMROOTDIR"/"$LOGFILE"
    else
        echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo adembak: -------         Remote iDempiere Backup FAILED!             ------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo . 
        exit 1
    fi
else
    echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo adembak: -------          Local iDempiere Backup FAILED!             ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo  .
    exit 1
fi
echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo edembak: -------         COMPLETED iDempiere Daily Backup            ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo .
exit 0
