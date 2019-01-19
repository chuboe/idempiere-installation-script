#!/bin/bash

# NOTE: syncApplied now a part of core:
# https://idempiere.atlassian.net/browse/IDEMPIERE-3655
# TODO: need to determine if action needed

#bring chuboe.properties into context
source chuboe.properties

DATABASE=$CHUBOE_PROP_DB_NAME
USER=$CHUBOE_PROP_DB_USERNAME
ADDPG="-h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT"

MIGRATIONDIR=${1:-~/hgAdempiere/localosgi/migration}
cd $MIGRATIONDIR

sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -d $DATABASE -U $USER $ADDPG -q -t -c "select name from ad_migrationscript" | sed -e 's:^ ::' | grep -v '^$' | sort > /tmp/lisDB.txt

> /tmp/lisFS.txt
FOLDERLIST="i2.0 i2.0z i2.1 i2.1z i3.1 i3.1z i4.1 i4.1z i5.1 i5.1z"
for FOLDER in $FOLDERLIST
do
    if [ -d ${FOLDER}/postgresql ]
    then
        cd ${FOLDER}/postgresql
        ls *.sql | sort >> /tmp/lisFS.txt
        cd ../..
    fi
done
sort -o /tmp/lisFS.txt /tmp/lisFS.txt
sort -o /tmp/lisDB.txt /tmp/lisDB.txt

MSGERROR=""
APPLIED=N
for i in `comm -13 /tmp/lisDB.txt /tmp/lisFS.txt`
do
    SCRIPT=`find . -name "$i" -print | fgrep -v /oracle/`
    OUTFILE=/tmp/`basename "$i" .sql`.out
    sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -d $DATABASE -U $USER $ADDPG -f "$SCRIPT" 2>&1 | tee "$OUTFILE"
    if fgrep "ERROR:
FATAL:" "$OUTFILE" > /dev/null 2>&1
    then
        MSGERROR="$MSGERROR
**** ERROR ON FILE $OUTFILE - Please verify ****"
    fi
    APPLIED=Y
done
if [ x$APPLIED = xY ]
then
    for i in processes_post_migration/postgresql/*.sql
    do
        OUTFILE=/tmp/`basename "$i" .sql`.out
        sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -d $DATABASE -U $USER $ADDPG -f "$i" 2>&1 | tee "$OUTFILE"
        if fgrep "ERROR:
FATAL:" "$OUTFILE" > /dev/null 2>&1
        then
            MSGERROR="$MSGERROR
**** ERROR ON FILE $OUTFILE - Please verify ****"
        fi
    done
else
    echo "Database is up to date, no scripts to apply"
fi
if [ -n "$MSGERROR" ]
then
    echo "$MSGERROR"
fi
# checkApplied.sh
