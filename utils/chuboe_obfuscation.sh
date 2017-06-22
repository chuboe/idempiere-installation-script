#!/bin/bash
# Created Version 1 Chuck Boecking

######################################
# This file is dangerous. It will overwrite your database.
# This script should only be executed from a development instance - NOT PRODUCTION.
######################################

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
DATABASE_OB="obfus"
DATABASE_TMP_EXPORT="/tmp/obtempout.bak"

echo LOGFILE=$LOGFILE >> $LOGFILE
echo NOTE: writing logs here: $LOGFILE
echo ADEMROOTDIR=$ADEMROOTDIR >> $LOGFILE

cd $ADEMROOTDIR/utils
echo ademres: ------------------------------------------------------------------- >> $LOGFILE
echo ademres: -------            STARTING iDempiere Obfuscation           ------- >> $LOGFILE
echo ademres: ------------------------------------------------------------------- >> $LOGFILE

if [[ $CHUBOE_PROP_IS_TEST_ENV = "Y" ]]; then
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    echo ademres: -------              This is a Dev Envrionment              ------- >> $LOGFILE
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
else
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    echo ademres: -------            STOPPING Not a Dev Envrionment           ------- >> $LOGFILE
    echo ademres: ------------------------------------------------------------------- >> $LOGFILE
    exit 1
fi #end if dev environment check
echo NOTE: Ignore errors related to myEnvironment.sav
if sudo -u $IDEMPIEREUSER "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> $LOGFILE
then
    echo adembak: Local Backup Succeeded.  >> $LOGFILE
else
    echo adembak: ------------------------------------------------------------------- >> $LOGFILE
    echo adembak: -------          Local iDempiere Backup FAILED!             ------- >> $LOGFILE
    echo adembak: ------------------------------------------------------------------- >> $LOGFILE
    echo  .
    exit 1
fi

#drop the existing obfuscated database if present
sudo -u postgres dropdb $DATABASE_OB
#export the existing database
sudo -u postgres pg_dump $DATABASE -Fc > $DATABASE_TMP_EXPORT
#create the obfuscated database
sudo -u postgres createdb $DATABASE_OB
#restore existing database to obfuscated database
sudo -u postgres pg_restore -Fc -d $DATABASE_OB $DATABASE_TMP_EXPORT
#remove old database export file
sudo rm $DATABASE_TMP_EXPORT

psql -d $DATABASE_OB -U $USER $ADDPG -f "$CHUBOE_UTIL_HG"/utils/chuboe_obfuscation.sql >> $LOGFILE
    echo adembak: ------------------------------------------------------------------- >> $LOGFILE
    echo edembak: -------         FINISHED iDempiere Obfuscation              ------- >> $LOGFILE
    echo adembak: ------------------------------------------------------------------- >> $LOGFILE
    echo .
exit 0
