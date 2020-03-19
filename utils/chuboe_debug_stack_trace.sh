#!/bin/bash
# Adaptation of script from eclipse.org http://wiki.eclipse.org/How_to_report_a_deadlock#jstackSeries_--_jstack_sampling_in_fixed_time_intervals_.28tested_on_Linux.29

pid=`jcmd | grep "[0-9]* /opt/idempiere-server" -o | grep "[0-9]*" -o`

count=${1:-10}  # defaults to 10 times
delay=${2:-1} # defaults to 1 second

while [ $count -gt 0 ]
do
    jstack $pid >jstack.$pid.$(date +%s.%N)
    top -H -b -n1 -p $pid >top.$pid.$(date +%s.%N)
    sleep $delay
    let count--
    echo -n "."
done
