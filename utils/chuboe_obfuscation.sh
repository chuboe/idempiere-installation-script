#!/bin/bash
#Version 1 - Chuck Boecking - created
#Version 2 - Chuck Boecking - moved obfuscation to separate database on the same instance

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
EXPORT_DIR="/tmp/"
DATABASE_OB="obfus"
DATABASE_TMP_EXPORT="obtempout.bak"
DATABASE_OB_EXPORT="ExpDatObfus.dmp"
DATABASE_OB_JAR="ExpDatObfus_"`date +%Y%m%d`_`date +%H%M%S`".jar"
CHUBOE_AWS_S3_BUCKET_SUB="BucketName/SubBucketName"
CHUBOE_AWS_S3_BUCKET=s3://$CHUBOE_AWS_S3_BUCKET_SUB/

echo ADEMROOTDIR=$ADEMROOTDIR
echo your backup will be available at:
echo https://s3.amazonaws.com/$CHUBOE_AWS_S3_BUCKET_SUB/$DATABASE_OB_JAR

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
echo NOTE: Ignore errors related to myEnvironment.sav
if sudo -u $IDEMPIEREUSER "$ADEMROOTDIR"/utils/RUN_DBExport.sh
then
    echo Local Backup Succeeded. 
else
    echo -------------------------------------------------------------------
    echo -------          Local iDempiere Backup FAILED!             -------
    echo -------------------------------------------------------------------
    echo  .
    exit 1
fi

echo drop the obfuscated database if present
echo NOTE: ignore errors on drop obfuscated database
dropdb $ADDPG -U $USER $DATABASE_OB
echo export the existing iDempiere database
pg_dump $ADDPG -U $USER $DATABASE -Fc > $EXPORT_DIR/$DATABASE_TMP_EXPORT
echo create the obfuscated database
createdb $ADDPG -U $USER $DATABASE_OB
echo restore existing iDempiere database to obfuscated database
pg_restore $ADDPG -U $USER -Fc -d $DATABASE_OB $EXPORT_DIR/$DATABASE_TMP_EXPORT
echo remove old database export file
sudo rm $EXPORT_DIR/$DATABASE_TMP_EXPORT

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
pg_dump $ADDPG --no-owner -U $USER $DATABASE_OB > $EXPORT_DIR/$DATABASE_OB_EXPORT

echo drop the obfuscated database -- no longer needed
dropdb $ADDPG -U $USER $DATABASE_OB

echo jar export
cd $EXPORT_DIR
jar cvfM $DATABASE_OB_JAR $DATABASE_OB_EXPORT

echo add osgi plugin inventory to the jar file - useful for developers
/$CHUBOE_PROP_UTIL_HG_UTIL_PATH/chuboe_osgi_ss.sh > osgi_inventory.txt
jar -uf $DATABASE_OB_JAR osgi_inventory.txt

echo NOTE: you can find the exported database here: $EXPORT_DIR/$DATABASE_OB_JAR
sudo rm $EXPORT_DIR/$DATABASE_OB_EXPORT

#push jar to S3 directly from this server
#uncomment below if needed
#echo Push $EXPORT_DIR/$DATABASE_OB_JAR to $CHUBOE_AWS_S3_BUCKET
#aws s3 cp $EXPORT_DIR/$DATABASE_OB_JAR $CHUBOE_AWS_S3_BUCKET --acl public-read

echo -------------------------------------------------------------------
echo COPY PASTE THE FOLLOWING TO UPLOAD TO S3 FROM YOUR HOME COMPUTER
echo -------------------------------------------------------------------
echo exit
echo scp ubuntu@\$IP_YOUR_SERVER_APP:$EXPORT_DIR/$DATABASE_OB_JAR \~/Downloads/.
echo cd \~/Downloads/
echo aws s3 cp $DATABASE_OB_JAR $CHUBOE_AWS_S3_BUCKET --acl public-read-write
echo https://s3.amazonaws.com/$CHUBOE_AWS_S3_BUCKET_SUB/$DATABASE_OB_JAR



echo -------------------------------------------------------------------
echo -------         FINISHED iDempiere Obfuscation              -------
echo -------------------------------------------------------------------
echo .
exit 0