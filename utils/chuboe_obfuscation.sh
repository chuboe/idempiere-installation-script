#!/bin/bash
#Version 1 - Chuck Boecking - created
#Version 2 - Chuck Boecking - moved obfuscation to separate database

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

echo ADEMROOTDIR=$ADEMROOTDIR

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

#drop the obfuscated database if present
echo NOTE: ignore errors on drop obfuscated database
dropdb $ADDPG -U $USER $DATABASE_OB
#export the existing iDempiere database
pg_dump $ADDPG -U $USER $DATABASE -Fc > $EXPORT_DIR/$DATABASE_TMP_EXPORT
#create the obfuscated database
createdb $ADDPG -U $USER $DATABASE_OB
#restore existing iDempiere database to obfuscated database
pg_restore $ADDPG -U $USER -Fc -d $DATABASE_OB $EXPORT_DIR/$DATABASE_TMP_EXPORT
#remove old database export file
sudo rm $EXPORT_DIR/$DATABASE_TMP_EXPORT

#execute the obfuscation sql script
psql -d $DATABASE_OB -U $USER $ADDPG -f "$CHUBOE_UTIL_HG"/utils/chuboe_obfuscation.sql

#dump the obfuscated database
pg_dump $ADDPG --no-owner -U $USER $DATABASE_OB > $EXPORT_DIR/$DATABASE_OB_EXPORT

#jar export
cd $EXPORT_DIR
jar cvfM $DATABASE_OB_JAR $DATABASE_OB_EXPORT
echo NOTE: you can find the exported database here: $EXPORT_DIR/$DATABASE_OB_JAR
sudo rm $EXPORT_DIR/$DATABASE_OB_EXPORT

echo -------------------------------------------------------------------
echo -------         FINISHED iDempiere Obfuscation              -------
echo -------------------------------------------------------------------
echo .
exit 0