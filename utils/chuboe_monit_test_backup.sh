#!/bin/bash
FILE="$1"

[ "$FILE" == "" ] && { echo "Usage: $0 filename"; exit 1; }
if [ -e "$FILE" ];
then
   echo "File $FILE exist."

   # time since last modification
   AGE_IN_SECONDS=$(($(date +%s) - $(date +%s -r $FILE)))
   echo "Time since last modification: "$AGE_IN_SECONDS
   test $AGE_IN_SECONDS -lt 90000 # exits with non 0 if older than 24 hours

   # size
   MINIMIM_SIZE=30000000
   ACTUAL_SIZE=$(wc -c <"$FILE")
   echo "actual file size: "$ACTUAL_SIZE
   test $ACTUAL_SIZE -gt $MINIMIM_SIZE
else
   echo "File $FILE does not exist" >&2
   exit 1
fi

# to see exit code of this script: echo $?