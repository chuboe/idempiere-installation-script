#!/bin/bash
# Version 1 Mike Stroven - created
# Version 2 Sandy Corsillo - enhanced to use s3cmd
# Version 3 Chuck Boecking - added more variables
# Version 4 Chuck Boecking - fixed bug where script copied multiple files to latest
# Version 5 Chris Greene - Changed to use AWS CLI


#Bring chuboe.properties into context
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_db_backup.log"
ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
LOCALBACKARCHIVEDIR="$CHUBOE_PROP_BACKUP_LOCAL_PATH/archive"
LOCALBACKLATESTDIR="$CHUBOE_PROP_BACKUP_LOCAL_PATH/latest"
ARCHIVEBUCKET=$CHUBOE_PROP_BACKUP_ARCHIVE_S3_BUCKET
LATESTBUCKET=$CHUBOE_PROP_BACKUP_LATEST_S3_BUCKET
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

mkdir $LOCALBACKARCHIVEDIR

if 
    echo NOTE: exporting database >> "$LOGFILE"
    sudo -u $IDEMPIEREUSER "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$LOGFILE"
    cp "$ADEMROOTDIR"/data/ExpDat????????_??????.jar "$LOCALBACKARCHIVEDIR"/
    sudo rm "$ADEMROOTDIR"/data/ExpDat????????_??????.jar
then
    echo Prepare latest directory >> "$LOGFILE"
    echo Ignore error stating directory already exists. >> "$LOGFILE"
    mkdir $LOCALBACKLATESTDIR
    rm "$LOCALBACKLATESTDIR"/*.jar
    cd "$LOCALBACKARCHIVEDIR"/

    #copy most recent backup to latest folder
    ls -t ExpDat*.jar | head -1 | awk '{print "cp " $0 " ../latest/"$0}' | sh

    echo Local Backup Succeeded.  Copying to S3 bucket. >> "$LOGFILE"
    if 
        # fully qualified path to support running from cron
        aws s3 sync "$LOCALBACKARCHIVEDIR"/ s3://"$ARCHIVEBUCKET"/ >> "$LOGFILE"
        aws s3 sync "$LOCALBACKLATESTDIR"/ s3://"$LATESTBUCKET"/ --delete >> "$LOGFILE"
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


# Below is an example AWS IAM Permission Policy that is compatible with this script. Note not all below permissions are necessary
#{
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Sid": "VisualEditor0",
#            "Effect": "Allow",
#            "Action": [
#                "s3:PutObject",
#                "s3:GetObjectAcl",
#                "s3:GetObject",
#                "s3:ListBucketMultipartUploads",
#                "s3:GetObjectRetention",
#                "s3:ListBucketVersions",
#                "s3:GetObjectTagging",
#                "s3:ListBucket",
#                "s3:GetObjectLegalHold",
#                "s3:ListMultipartUploadParts"
#            ],
#            "Resource": [
#                "arn:aws:s3:::CHANGETOARCHIVEBUCKET",
#                "arn:aws:s3:::CHANGETOARCHIVEBUCKET/*"
#            ]
#        },
#        {
#            "Sid": "VisualEditor1",
#            "Effect": "Allow",
#            "Action": [
#                "s3:PutObject",
#                "s3:GetObjectAcl",
#                "s3:GetObject",
#                "s3:ListBucketMultipartUploads",
#                "s3:GetObjectRetention",
#                "s3:ListBucketVersions",
#                "s3:GetObjectTagging",
#                "s3:ListBucket",
#                "s3:GetObjectLegalHold",
#                "s3:DeleteObject",
#                "s3:ListMultipartUploadParts"
#            ],
#            "Resource": [
#                "arn:aws:s3:::CHANGETOLATESTBUCKET/*",
#                "arn:aws:s3:::CHANGETOLATESTBUCKET"
#            ]
#        },
#        {
#            "Sid": "VisualEditor2",
#            "Effect": "Allow",
#            "Action": [
#                "s3:ListStorageLensConfigurations",
#                "s3:GetAccessPoint",
#                "s3:GetAccountPublicAccessBlock",
#                "s3:ListAllMyBuckets",
#                "s3:ListAccessPoints",
#                "s3:ListJobs"
#            ],
#            "Resource": "*"
#        }
#    ]
#}
