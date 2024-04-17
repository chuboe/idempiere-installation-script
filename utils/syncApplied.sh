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

sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -b -d $DATABASE -U $USER $ADDPG -q -t -c "select name from ad_migrationscript" | sed -e 's:^ ::' | grep -v '^$' | sort > /tmp/lisDB.txt

> /tmp/lisFS.txt
FOLDERLIST="i2.0 i2.0z i2.1 i2.1z i3.1 i3.1z i4.1 i4.1z i5.1 i5.1z i6.1 i6.1z i6.2 i6.2z i7.1 i7.1z i8.1 i8.1z i8.2 i8.2z i9 iD10 iD11"
for FOLDER in $FOLDERLIST
do
    if [ -d ${FOLDER}/postgresql ]
    then
        cd ${FOLDER}/postgresql
        ls *.sql | sort >> /tmp/lisFS.txt
        cd ../..
    fi
done

#ensure no dulicates
sort -u -o /tmp/lisFS.txt /tmp/lisFS.txt
sort -u -o /tmp/lisDB.txt /tmp/lisDB.txt

MSGERROR=""
APPLIED=N
DEFAULT_FILE_COUNT=1
comm -13 /tmp/lisDB.txt /tmp/lisFS.txt > /tmp/lisPENDING.txt

#ensure no dulicates
sort -u -o /tmp/lisPENDING.txt /tmp/lisPENDING.txt

while read -r FILE
do
    SCRIPT=`find . -name "$FILE" -print | fgrep -v /oracle/`
    NO_OF_FILE_COUNT=`find . -name "$FILE" -print | fgrep -v /oracle/ | wc -l`

    if [ "$NO_OF_FILE_COUNT" -gt "$DEFAULT_FILE_COUNT" ];
    then
        echo "Found same name scripts in mutiple folder: $SCRIPT"
        SCRIPT=`echo $SCRIPT | cut -d ' ' -f 1`
    fi
    echo "Applying $SCRIPT"
    OUTFILE=/tmp/`basename "$FILE" .sql`.out
    sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -b -d $DATABASE -U $USER $ADDPG -f "$SCRIPT" 2>&1 | tee "$OUTFILE"
    if fgrep "ERROR:
FATAL:" "$OUTFILE" > /dev/null 2>&1
    then
        MSGERROR="$MSGERROR
**** ERROR ON FILE $OUTFILE - Please verify ****"
    fi
    APPLIED=Y
done < /tmp/lisPENDING.txt

if [ x$APPLIED = xY ]
then
    for i in processes_post_migration/postgresql/*.sql
    do
        OUTFILE=/tmp/`basename "$i" .sql`.out
        sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -b -d $DATABASE -U $USER $ADDPG -f "$i" 2>&1 | tee "$OUTFILE"
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
