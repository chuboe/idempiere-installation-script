#!/bin/bash

source chuboe.properties
IDPID=`sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jcmd | grep "[0-9]* /opt/idempiere-server" -o | grep "[0-9]*" -o`

echo pid=$IDPID

sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jcmd $IDPID GC.heap_dump |& tee /tmp/heap_dump.$IDPID.$(date +%s.%N)
top -H -b -n1 -p $IDPID |& tee /tmp/top.$IDPID.$(date +%s.%N)
