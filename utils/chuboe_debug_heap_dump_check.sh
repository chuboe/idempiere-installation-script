#!/bin/bash
source chuboe_last_heap_check.txt
maxheapused=8000000

pid=$(ps -aux  | grep -v root | grep '/usr/lib/jvm/java-11-openjdk-amd64/bin/java -Xms' | awk '{print $2}')
heapused=`jcmd $pid GC.heap_info | grep garbage-first | awk '{print $6}' | cut -d 'K' -f1`
totalheap=`jcmd $pid GC.heap_info | grep garbage-first | awk '{print $4}' | cut -d 'K' -f1`
#totalheap=18874368
#totalheap=331776
#echo "Used: $heapused"
heapfree=$(($totalheap - $heapused))
heapfreeinmb=$(($heapfree/1024))

echo "$(date +%Y%m%d)_$(date +%H%M%S): Total Heap: $totalheap Used Heap: $heapused Free Heap in MB $heapfreeinmb" >> heap_dump.log
echo "Max Heap Used: $maxheapused" >> heap_dump.log
echo "Last Heap Check :$last_heap_check" >> heap_dump.log
echo "last_heap_used=$heapused" > chuboe_last_heap_used.txt
echo "last_heap_free=$heapfree" > chuboe_last_heap_free.txt

if [ $heapused -gt $maxheapused ]
#if [ 2 -gt 1 ]
then
	echo "Heap Over" >> heap_dump.log
	if [ $last_heap_check -eq 0 ]
	then
		echo "Last Heap Under, HEAP DUMP TRIGGERED" >> heap_dump.log
		echo "last_heap_check=1">chuboe_last_heap_check.txt
        	cd /opt/chuboe/idempiere-installation-script/utils/
	        sudo -u ubuntu ./chuboe_debug_heap_dump.sh
		echo " Production Performed a Heap Dump. Heap Used = $heapused" | mail -s " Prod Heap Dump Triggered" chuck@chuboe.com sam@chuboe.com
	else
		echo "Last Heap Over, Skipping Heap Push" >> heap_dump.log
		echo "last_heap_check=1">chuboe_last_heap_check.txt
	fi
else
	echo "Heap Under">> heap_dump.log
	echo "last_heap_check=0">chuboe_last_heap_check.txt
fi
