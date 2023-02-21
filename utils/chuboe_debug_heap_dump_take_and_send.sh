#!/bin/bash

source chuboe.properties
IDPID=`sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jcmd | grep "[0-9]* /opt/idempiere-server" -o | grep "[0-9]*" -o`
IDDATE=`date +%Y%m%d`_`date +%s.%N`
echo Date = "$IDDATE"
CHUBOE_AWS_S3_BUCKET_SUB=$CHUBOE_PROP_DEBUG_DEV_SHARE_BUCKET
CHUBOE_AWS_S3_BUCKET=s3://$CHUBOE_AWS_S3_BUCKET_SUB/

echo pid=$IDPID
echo date=$IDDATE

count=${1:-1}  # defaults to 1 time
delay=${2:-1} # defaults to 1 second

while [ $count -gt 0 ]
do
    heap_dump_file=heap_dump.$IDPID.$IDDATE.$CHUBOE_PROP_WEBUI_IDENTIFICATION.$count
    heap_top_file=heap_top.$IDPID.$IDDATE.$CHUBOE_PROP_WEBUI_IDENTIFICATION.$count

    sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jcmd $IDPID GC.heap_dump /tmp/$heap_dump_file
    sudo chown $USER:$USER /tmp/$heap_dump_file
    top -H -b -n1 -p $IDPID |& tee /tmp/$heap_top_file
    sudo chown $USER:$USER /tmp/$heap_top_file

    echo Push files to S3...
    echo aws s3 cp /tmp/$heap_dump_file $CHUBOE_AWS_S3_BUCKET
    aws s3 cp /tmp/$heap_dump_file $CHUBOE_AWS_S3_BUCKET
    echo https://s3.amazonaws.com/$CHUBOE_AWS_S3_BUCKET_SUB/$heap_dump_file

    echo aws s3 cp /tmp/$heap_top_file $CHUBOE_AWS_S3_BUCKET
    aws s3 cp /tmp/$heap_top_file $CHUBOE_AWS_S3_BUCKET
    echo https://s3.amazonaws.com/$CHUBOE_AWS_S3_BUCKET_SUB/$heap_top_file

    sleep $delay
    let count--
    echo -n "."
done

echo files created:
ls -ltrh /tmp/*$IDDATE*

# see chuboe_obfuscation.sh for details on how to create dev s3 buckets
