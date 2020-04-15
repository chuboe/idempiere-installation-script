#!/bin/bash
# Adaptation of script from eclipse.org http://wiki.eclipse.org/How_to_report_a_deadlock#jstackSeries_--_jstack_sampling_in_fixed_time_intervals_.28tested_on_Linux.29
# Adaptation of https://github.com/cqsupport/jstackSeries.sh/blob/master/jstackSeries.sh

source chuboe.properties
pid=`sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jcmd | grep "[0-9]* /opt/idempiere-server" -o | grep "[0-9]*" -o`
iddate=$(date +%s.%N)
CHUBOE_AWS_S3_BUCKET_SUB=$CHUBOE_PROP_DEBUG_DEV_SHARE_BUCKET
CHUBOE_AWS_S3_BUCKET=s3://$CHUBOE_AWS_S3_BUCKET_SUB/

echo pid=$pid
echo date=$iddate

count=${1:-1}  # defaults to 1 time
delay=${2:-1} # defaults to 1 second

while [ $count -gt 0 ]
do
    stack_trace_file=stack_trace.$pid.$iddate.$CHUBOE_PROP_WEBUI_IDENTIFICATION.$count
    stack_top_file=stack_top.$pid.$iddate.$CHUBOE_PROP_WEBUI_IDENTIFICATION.$count

    sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jstack $pid |& tee /tmp/$stack_trace_file
    top -H -b -n1 -p $pid |& tee /tmp/$stack_top_file

    sudo chown $USER:$USER /tmp/$stack_trace_file
    echo aws s3 cp /tmp/$stack_trace_file $CHUBOE_AWS_S3_BUCKET
    aws s3 cp /tmp/$stack_trace_file $CHUBOE_AWS_S3_BUCKET

    sudo chown $USER:$USER /tmp/$stack_top_file
    echo aws s3 cp /tmp/$stack_top_file $CHUBOE_AWS_S3_BUCKET
    aws s3 cp /tmp/$stack_top_file $CHUBOE_AWS_S3_BUCKET

    sleep $delay
    let count--
    echo -n "."
done

echo files created:
ls -ltrh /tmp/*$iddate*