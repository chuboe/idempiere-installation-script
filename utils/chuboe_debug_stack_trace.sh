#!/bin/bash
# Adaptation of script from eclipse.org http://wiki.eclipse.org/How_to_report_a_deadlock#jstackSeries_--_jstack_sampling_in_fixed_time_intervals_.28tested_on_Linux.29
# Adaptation of https://github.com/cqsupport/jstackSeries.sh/blob/master/jstackSeries.sh

source chuboe.properties
pid=`sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jcmd | grep "[0-9]* /opt/idempiere-server" -o | grep "[0-9]*" -o`
iddate=$(date +%s.%N)

echo pid=$pid
echo date=$iddate

count=${1:-1}  # defaults to 1 time
delay=${2:-1} # defaults to 1 second

while [ $count -gt 0 ]
do
    sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER jstack $pid |& tee /tmp/stack_trace.$pid.$iddate.$count
    top -H -b -n1 -p $pid |& tee /tmp/stack_top.$pid.$iddate.$count
    sleep $delay
    let count--
    echo -n "."
done

echo set file ownership to $USER
sudo chown $USER:$USER /tmp/*$iddate*

echo see /tmp/ for output. execute the following command to see latest files in /tmp/
echo ls -ltrh /tmp/*$iddate*
echo files created:
ls -ltrh /tmp/*$iddate*