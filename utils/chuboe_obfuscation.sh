#!/bin/bash
#Version 1 - Chuck Boecking - created
#Version 2 - Chuck Boecking - moved obfuscation to separate database on the same instance

#Open Items
#1. Need to include the /opt/idempiere-server/customization-jar/ directory in jar that is uploaded. This helps developers know exactly what is deployed without needing to recreate jars from code.

while getopts eq option
do
case "${option}"
in
e)  EXIT_AFTER_INITIAL_BACKUP=Y
    echo exit after initial backup!! Be aware this data is not obfuscated!!
    ;;
q)  QUICK_AND_DIRTY='-T ''*deleteme*'' -T ''*delme*'' --exclude-table-data=''ad_pinstance*'' --exclude-table-data=''t_*'' --exclude-table-data=r_requestupdate --exclude-table-data=r_requestaction --exclude-table-data=''chuboe_trialbalance*'' --exclude-table-data=''chuboe_validation*'' --exclude-table-data=ad_wf_process --exclude-table-data=ad_wf_activity --exclude-table-data=ad_wf_eventaudit --exclude-table-data=ad_changelog --exclude-table-data=ad_attachment --exclude-table-data=''fact_acct*'' --exclude-table-data=ad_usermail --exclude-table-data=ad_issue'
    echo export quick and dirty!!
    ;;
esac
done

#If you use the -e and -q options, you can create a fast and small backup of an otherwise large database.
#This scenario is advantageous when trying to populate a developer copy of the database from a production or uat server.
#Below are the commands you can use from your remote machine (example: developer instance) to restore a local copy of the database.
#Note: be aware the below commands will blow away the iDempiere database on what ever server you execute them from. Always keep a valid backup of important data!!!
    # rsync -a --delete --progress chuboe@IP_OF_UAT_SERVER:/tmp/obtempout.bak/ /tmp/obtempout.bak/
    # dropdb -U adempiere idempiere
    # createdb -U adempiere idempiere
    # pg_restore -d idempiere -U adempiere -Fd /tmp/obtempout.bak/

#bring chuboe.properties into context
source chuboe.properties

CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_db_obfuscate.log"
ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
DATABASE=$CHUBOE_PROP_DB_NAME
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
USER=$CHUBOE_PROP_DB_USERNAME
ADDPG="-h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT"
EXPORT_DIR="/opt/chuboe/idempiere-installation-script/chuboe_backup/"
DATABASE_OB="obfus"
DATABASE_TMP_EXPORT="obfuscate_tmp"
DATABASE_OB_EXPORT="obfuscate_complete"
DATABASE_OB_JAR="ExpDatObfus_"`date +%Y%m%d`_`date +%H%M%S`".jar"
CHUBOE_AWS_S3_BUCKET_SUB=$CHUBOE_PROP_BACKUP_S3_BUCKET
CHUBOE_AWS_S3_BUCKET=s3://$CHUBOE_AWS_S3_BUCKET_SUB/
# You may update the number of cores used from default below
BACKUP_RESTORE_JOBS=$CHUBOE_PROP_BACKUP_RESTORE_JOBS

cd $ADEMROOTDIR/utils
echo -------------------------------------------------------------------
echo -------            STARTING iDempiere Obfuscation           -------
echo -------------------------------------------------------------------

if [[ $CHUBOE_PROP_IS_TEST_ENV = "Y" ]]; then
    echo -------------------------------------------------------------------
    echo -------              This is a Dev Envrionment              -------
    echo -------------------------------------------------------------------
else
    echo -------------------------------------------------------------------
    echo -------            STOPPING Not a Dev Envrionment           -------
    echo -------------------------------------------------------------------
    exit 1
fi #end if dev environment check

echo drop the obfuscated database if present
echo NOTE: ignore errors on drop obfuscated database
dropdb $ADDPG -U $USER $DATABASE_OB
echo remove old database export file
echo NOTE: ignore errors on remove old database export file
sudo rm -r $EXPORT_DIR/$DATABASE_TMP_EXPORT
echo export the existing iDempiere database
pg_dump $ADDPG $QUICK_AND_DIRTY -U $USER $DATABASE -Fd -j $BACKUP_RESTORE_JOBS -f $EXPORT_DIR/$DATABASE_TMP_EXPORT
if [[ $EXIT_AFTER_INITIAL_BACKUP = "Y" ]]; then
    echo Exiting after initial backup!
    echo ...To use existing backup as idempiere database...
    echo sudo service idempiere stop
    echo dropdb $ADDPG -U $USER idempiere
    echo createdb $ADDPG -U $USER idempiere
    echo pg_restore $ADDPG -U $USER -Fd -j $BACKUP_RESTORE_JOBS -d idempiere $EXPORT_DIR/$DATABASE_TMP_EXPORT
    exit 0
fi

echo create the obfuscated database
createdb $ADDPG -U $USER $DATABASE_OB
echo restore existing iDempiere database to obfuscated database
pg_restore $ADDPG -U $USER -Fd -j $BACKUP_RESTORE_JOBS -d $DATABASE_OB $EXPORT_DIR/$DATABASE_TMP_EXPORT
echo remove old database export file
sudo rm -r $EXPORT_DIR/$DATABASE_TMP_EXPORT

echo execute the obfuscation sql script
psql -d $DATABASE_OB -U $USER $ADDPG -f "$CHUBOE_UTIL_HG"/utils/chuboe_obfuscation.sql

# uncomment if you wish to review the data before the script continues
# read -p "Press enter to continue - check the obfuscated database before continue"

# check to confirm the obfuscation script ran successfully
# the -t removes the column header and the xargs trims the string
# I cannot figure out how to get rid of the time in the result
RecordExists=$(psql -U $USER -d $DATABASE_OB -t -c "select exists (select * from c_bpartner where name = 'bp'||c_bpartner_id)" | xargs)
echo Did obfuscation succeed:$RecordExists
# :0:1 extracts the first character
if [[ ${RecordExists:0:1} == "t" ]]
then
    echo HERE: successful obfuscation
else
    echo HERE: failed obfuscation
    exit 1
fi

echo dump the obfuscated database
sudo rm -r $EXPORT_DIR/$DATABASE_OB_EXPORT
#pg_dump $ADDPG --no-owner -U $USER $DATABASE_OB > $EXPORT_DIR/$DATABASE_OB_EXPORT
pg_dump $ADDPG --no-owner -U $USER $DATABASE_OB -Fd -j $BACKUP_RESTORE_JOBS -f $EXPORT_DIR/$DATABASE_OB_EXPORT

echo drop the obfuscated database -- no longer needed
dropdb $ADDPG -U $USER $DATABASE_OB

cd $EXPORT_DIR/$DATABASE_OB_EXPORT
echo add osgi plugin inventory to the jar file - useful for developers
/$CHUBOE_PROP_UTIL_HG_UTIL_PATH/chuboe_osgi_ss.sh > osgi_inventory.txt

echo NOTE: you can find the exported database here: $EXPORT_DIR/$DATABASE_OB_JAR

#push jar to S3 directly from this server
#uncomment below if needed
echo aws s3 sync --delete $EXPORT_DIR/$DATABASE_OB_EXPORT $CHUBOE_AWS_S3_BUCKET
aws s3 sync --delete $EXPORT_DIR/$DATABASE_OB_EXPORT $CHUBOE_AWS_S3_BUCKET
#echo https://s3.amazonaws.com/$CHUBOE_AWS_S3_BUCKET_SUB/$DATABASE_OB_JAR

echo -------------------------------------------------------------------
echo -------         FINISHED iDempiere Obfuscation              -------
echo -------------------------------------------------------------------
echo .
exit 0


# {{{ Example IAM
# Below is an example AWS IAM Permission Policy that is compatible with this script.
# Note this policy combines multiple statements into a single policy.
# Note
#   - dev_share_devname_custname = the name of the AIM you create to share with your dev team
#   - dev_share_devname_custname_server = the name of the IAM on configure on you local server
#   - chuboe-obfuscation-devname-custname = name of S3 Bucket you create to support sharing dev artifacts
# Action: substitute in your context details. Example substitutions that make the policy applicable to your situation:
#   - DevName => Logilite
#   - devname => logilite
#   - CustName => AcmeCo
#   - custname => acmeco
#   - the bucket name should also be added to chuboe.properties => CHUBOE_PROP_DEBUG_DEV_SHARE_BUCKET
# Action: Create IAM - you do not need to add these users to a group. The below policy will do what is needed to control access.
#   - dev_share_devname_custname (perform } first)
#   - dev_share_devname_custname_server (perform substituttions first)
# Note - there are a couple of scripts that share developer team details
#   - chuboe_debug_heap_dump.sh
#   - chuboe_debug_query_lock_utils.sql
#   - chuboe_debug_send_log_db.sh
#   - chuboe_debug_send_log_id.sh
#   - chuboe_debug_stack_trace.sh
#{
#    "Version": "2012-10-17",
#    "Id": "S3AccessPolicybfuscatedForDevNameCustName",
#    "Statement": [
#        {
#            "Sid": "ObfuscatedForDevNameCustName",
#            "Effect": "Allow",
#            "Principal": {
#                "AWS": "arn:aws:iam::863712138235:user/dev_share_devname_custname"
#            },
#            "Action": [
#                "s3:GetObject",
#                "s3:ListBucket"
#            ],
#            "Resource": [
#                "arn:aws:s3:::chuboe-obfuscation-devname-custname",
#                "arn:aws:s3:::chuboe-obfuscation-devname-custname/*"
#            ]
#        },
#        {
#            "Sid": "ObfuscatedForDevNameCustNameServer",
#            "Effect": "Allow",
#            "Principal": {
#                "AWS": "arn:aws:iam::863712138235:user/dev_share_devname_custname_server"
#            },
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
#                "arn:aws:s3:::chuboe-obfuscation-devname-custname",
#                "arn:aws:s3:::chuboe-obfuscation-devname-custname/*"
#            ]
#        }
#    ]
#}

# end of vim fold
#}}}
