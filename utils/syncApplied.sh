DATABASE=${1:-idempiere}
USER=adempiere
ADDPG=${2}   # i.e. "-h localhost -p 5432"

MIGRATIONDIR=${3:-~/hgAdempiere/localosgi/migration}
cd $MIGRATIONDIR

psql -d $DATABASE -U $USER $ADDPG -q -t -c "select name from ad_migrationscript" | sed -e 's:^ ::' | grep -v '^$' | sort > /tmp/lisDB.txt

> /tmp/lisFS.txt
for FOLDER in i2.1 i2.1z
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
    psql -d $DATABASE -U $USER $ADDPG -f "$SCRIPT" 2>&1 | tee "$OUTFILE"
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
        psql -d $DATABASE -U $USER $ADDPG -f "$i" 2>&1 | tee "$OUTFILE"
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
