#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
# Version 3 Chuck Boecking - added more variables
# Version 4 Chuck Boecking - fixed bug where script copied multiple files to latest
LOGFILE="/log/chuboe_db_backup.log"
ADEMROOTDIR="/opt/idempiere-server"
CHUBOE_UTIL="/opt/chuboe_utils/"
CHUBOE_UTIL_HG="$CHUBOE_UTIL/idempiere-installation-script/"
LOCALBACKDIR="chuboe_backup"
S3BUCKET="iDempiere_backup"
IDEMPIEREUSER="idempiere"

echo LOGFILE="$CHUBOE_UTIL_HG"/"$LOGFILE" >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$CHUBOE_UTIL_HG"/"$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo  -------          STARTING iDempiere Daily Backup            ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo  Executing RUN_DBExport.sh local backup utility. >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
if 
    sudo -u $IDEMPIEREUSER "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    cp "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/
then
    echo Prepare latest directory >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    mkdir "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/latest/
    rm "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/latest/*.jar
    cd "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/

    #copy most recent backup to latest folder
    ls -t ExpDat*.jar | head -1 | awk '{print "cp " $0 " latest/"$0}' | sh

    echo Local Backup Succeeded.  Copying to S3 bucket. >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    if 
        s3cmd sync "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/ s3://"$S3BUCKET"/
        s3cmd sync --delete "$CHUBOE_UTIL_HG"/"$LOCALBACKDIR"/latest/ s3://"$S3BUCKET"/latest/
    then
        echo Copy of backup files to S3 succeeded. >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    else
        echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
        echo  -------         Remote iDempiere Backup FAILED!             ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
        echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
        echo .
        exit 1
    fi
else
    echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo  -------          Local iDempiere Backup FAILED!             ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
    echo .
    exit 1
fi
echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo  -------         COMPLETED iDempiere Daily Backup            ------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo  ------------------------------------------------------------------- >> "$CHUBOE_UTIL_HG"/"$LOGFILE"
echo .
exit 0
