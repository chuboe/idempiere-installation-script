#!/bin/bash

MEMORYLABEL="tenured generation" #can change for different jave versions

IDPID=`jcmd | grep "[0-9]* /opt/idempiere-server" -o | grep "[0-9]*" -o`

if (( ${IDPID:-"bad"}=="bad" ))
then
        echo "idempiere not running, exiting 1"
        exit 1
fi

echo "$IDPID is the PID"
PERCENT=`jcmd $IDPID GC.heap_info | awk "/$MEMORYLABEL/,/% used/" | grep "[0-9]*% used" -o | grep "[0-9]*" -o`

echo "$PERCENT Percent"

if (( ${1:-70} > $PERCENT ))
then
        echo "Percent fine, exiting 0"
        exit 0
fi
echo "Percent too high, exiting 1"
exit 1

