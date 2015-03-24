#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
# Version 3 Chuck Boecking - added more variables
# Version 4 Chuck Boecking - fixed bug where script copied multiple files to latest
LOGFILE="/log/chuboe_db_backup.log"
ADEMROOTDIR="/opt/idempiere-server"
LOCALBACKDIR="chuboe_backup"
S3BUCKET="iDempiere_backup"

echo LOGFILE="$ADEMROOTDIR"/"$LOGFILE" >> "$ADEMROOTDIR"/"$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$ADEMROOTDIR"/"$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo  -------          STARTING iDempiere Daily Backup            ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo  Executing RUN_DBExport.sh local backup utility. >> "$ADEMROOTDIR"/"$LOGFILE"
if "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$ADEMROOTDIR"/"$LOGFILE"
mv "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$ADEMROOTDIR"/"$LOCALBACKDIR"/
then
    echo Prepare latest directory >> "$ADEMROOTDIR"/"$LOGFILE"
    mkdir "$ADEMROOTDIR"/"$LOCALBACKDIR"/latest/
    rm "$ADEMROOTDIR"/"$LOCALBACKDIR"/latest/*.jar
    cd "$ADEMROOTDIR"/"$LOCALBACKDIR"/

    #copy most recent backup to latest folder
    ls -t ExpDat*.jar | head -1 | awk '{print "cp " $0 " latest/"$0}' | sh

    echo Local Backup Succeeded.  Copying to S3 bucket. >> "$ADEMROOTDIR"/"$LOGFILE"
    if s3cmd sync "$ADEMROOTDIR"/"$LOCALBACKDIR"/ s3://"$S3BUCKET"/
       s3cmd sync --delete "$ADEMROOTDIR"/"$LOCALBACKDIR"/latest/ s3://"$S3BUCKET"/latest/
    then
        echo Copy of backup files to S3 succeeded. >> "$ADEMROOTDIR"/"$LOGFILE"
    else
        echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo  -------         Remote iDempiere Backup FAILED!             ------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
        echo .
        exit 1
    fi
else
    echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo  -------          Local iDempiere Backup FAILED!             ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo .
    exit 1
fi
echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo  -------         COMPLETED iDempiere Daily Backup            ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo  ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo .
exit 0
