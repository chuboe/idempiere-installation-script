#!/bin/bash

# Arguments:
#  1 - HOSTPATH including trailing /
#  2 - Filename
#  3 - local path prefix including trailing /
#  4 - (Optional) Jenkins Auth command
    # If it exists, test integrity with unzip.  If unzip integrity check succeeds, we're done.
    DOWNLOAD_SCRIPTNAME=$(readlink -f "$0")
    DOWNLOAD_SCRIPTPATH=$(dirname "$DOWNLOAD_SCRIPTNAME")
    if [ -e $3/$2 ]; then
        unzip -tq $3/$2
        if [ $? -eq 0 ]; then
            echo "HERE: downloadtestzip: $2 already downloaded"
            return 0
        fi
    fi
    echo "HERE: Download zip with params: " $1 $2 $3
    $DOWNLOAD_SCRIPTPATH/download.sh $1 $2 $3 "$4" || exit 1
    unzip -t $3/$2
    if [ $? -ne 0 ]
    then
        echo "HERE: downloadtestzip: $2 downloaded incorrectly - retry"
        exit 1
    fi
