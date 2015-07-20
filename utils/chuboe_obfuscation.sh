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

echo LOGFILE=$LOGFILE >> $LOGFILE
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

psql -d $DATABASE -U $USER $ADDPG -f "$CHUBOE_UTIL_HG"/utils/chuboe_obfuscation.sql >> $LOGFILE
    echo adembak: ------------------------------------------------------------------- >> $LOGFILE
    echo edembak: -------         FINISHED iDempiere Obfuscation              ------- >> $LOGFILE
    echo adembak: ------------------------------------------------------------------- >> $LOGFILE
    echo .
exit 0
