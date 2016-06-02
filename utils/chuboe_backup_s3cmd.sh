#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
# Version 3 Chuck Boecking - added more variables
# Version 4 Chuck Boecking - fixed bug where script copied multiple files to latest

#Bring chuboe.properties into context
source chuboe.properties
LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_db_backup.log"
ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
S3BUCKET=$CHUBOE_PROP_BACKUP_S3_BUCKET
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER

# Outstanding Features
### Add a cli option to append a text string to a current backup. 
###    Example: ./chuboe_backup_s3cmd -m "after_client_create". 
###    The result would be ExpDmp_DATE..._after_client_create.jar

echo LOGFILE="$LOGFILE" >> "$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo  ------------------------------------------------------------------- >> "$LOGFILE"
echo  -------          STARTING iDempiere Daily Backup            ------- >> "$LOGFILE"
echo  ------------------------------------------------------------------- >> "$LOGFILE"
echo  Executing RUN_DBExport.sh local backup utility. >> "$LOGFILE"

# Note: if you get a pg_dump server mismatch error when using RDS - read this to solve:
# http://stackoverflow.com/questions/12836312/postgresql-9-2-pg-dump-version-mismatch

if 
    echo NOTE: ignore errors about myEnvironment.sav
    sudo -u $IDEMPIEREUSER "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$LOGFILE"
    cp "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$LOCALBACKDIR"/
    sudo rm "$ADEMROOTDIR"/data/ExpDat????????_??????.jar
then
    echo Prepare latest directory >> "$LOGFILE"
    echo Ignore error stating directory already exists.
    mkdir "$LOCALBACKDIR"/latest/
    rm "$LOCALBACKDIR"/latest/*.jar
    cd "$LOCALBACKDIR"/

    #copy most recent backup to latest folder
    ls -t ExpDat*.jar | head -1 | awk '{print "cp " $0 " latest/"$0}' | sh

    echo Local Backup Succeeded.  Copying to S3 bucket. >> "$LOGFILE"
    if 
        s3cmd sync "$LOCALBACKDIR"/ s3://"$S3BUCKET"/
        s3cmd sync --delete-after "$LOCALBACKDIR"/latest/ s3://"$S3BUCKET"/latest/
    then
        echo Copy of backup files to S3 succeeded. >> "$LOGFILE"
    else
        echo  ------------------------------------------------------------------- >> "$LOGFILE"
        echo  -------         Remote iDempiere Backup FAILED!             ------- >> "$LOGFILE"
        echo  ------------------------------------------------------------------- >> "$LOGFILE"
        echo .
        exit 1
    fi
else
    echo  ------------------------------------------------------------------- >> "$LOGFILE"
    echo  -------          Local iDempiere Backup FAILED!             ------- >> "$LOGFILE"
    echo  ------------------------------------------------------------------- >> "$LOGFILE"
    echo .
    exit 1
fi
echo  ------------------------------------------------------------------- >> "$LOGFILE"
echo  -------         COMPLETED iDempiere Daily Backup            ------- >> "$LOGFILE"
echo  ------------------------------------------------------------------- >> "$LOGFILE"
echo .
exit 0
