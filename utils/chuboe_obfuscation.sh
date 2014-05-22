#!/bin/bash
# Created Version 1 Chuck Boecking

######################################
# This file is dangerous. It will overwrite your database.
# This script should only be executed from a development instance - NOT PRODUCTION.
######################################

LOGFILE="/log/chuboe_db_obfuscate.log"
ADEMROOTDIR="/opt/idempiere-server"
UTILSDIR="chuboe_utils"
DATABASE="idempiere"
USER="adempiere"
ADDPG="-h localhost -p 5432"

echo LOGFILE="$ADEMROOTDIR"/"$LOGFILE" >> "$ADEMROOTDIR"/"$LOGFILE"
echo ADEMROOTDIR="$ADEMROOTDIR" >> "$ADEMROOTDIR"/"$LOGFILE"

cd "$ADEMROOTDIR"/utils
echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo ademres: -------            STARTING iDempiere Obfuscation           ------- >> "$ADEMROOTDIR"/"$LOGFILE"
echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"

RESULT=$(ls -l $ADEMROOTDIR/$UTILSDIR/properties/CHUBOE_TEST_ENV_YES.txt | wc -l)
if [ $RESULT -ge 1 ]; then
    echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo ademres: -------              This is a Dev Envrionment              ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
else
    echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo ademres: -------            STOPPING Not a Dev Envrionment           ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo ademres: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    exit 1
fi #end if dev environment check
if "$ADEMROOTDIR"/utils/RUN_DBExport.sh >> "$ADEMROOTDIR"/"$LOGFILE"
then
    echo adembak: Local Backup Succeeded.  >> "$ADEMROOTDIR"/"$LOGFILE"
else
    echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo adembak: -------          Local iDempiere Backup FAILED!             ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo  .
    exit 1
fi

psql -d $DATABASE -U $USER $ADDPG -f "$ADEMROOTDIR"/"$UTILSDIR"/chuboe_obfuscation.sql >> "$ADEMROOTDIR"/"$LOGFILE"
    echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo edembak: -------         FINISHED iDempiere Obfuscation              ------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo adembak: ------------------------------------------------------------------- >> "$ADEMROOTDIR"/"$LOGFILE"
    echo .
exit 0
