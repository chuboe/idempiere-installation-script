#!/bin/bash

# Arguments:
#  1 - HOSTPATH including trailing /
#  2 - Filename
#  3 - local path prefix including trailing /
#  4 - (Optional) Jenkins Auth command
    # If it exists, test integrity with gzip.  If gzip integrity check succeeds, we're done.
    DOWNLOAD_SCRIPTNAME=$(readlink -f "$0")
    DOWNLOAD_SCRIPTPATH=$(dirname "$DOWNLOAD_SCRIPTNAME")
    if [ -e $3/$2 ]; then
        gzip -tq $3/$2
        if [ $? -eq 0 ]; then
            echo "HERE: downloadtestgz: $2 already downloaded"
            return
        fi
    fi
    echo "HERE: Downloading gz with params: " $1 $2 $3
    $DOWNLOAD_SCRIPTPATH/download.sh $1 $2 $3 $4 || exit 1
    gzip -tq $3/$2
    if [ $? -ne 0 ]
    then
        # DKA: If wget succeeds and unzip fails, then remove the downloaded file so they start the download over when user re-runs script 
        # rm $3/$2
        echo "HERE: downloadtestgz: $2 downloaded incorrectly - retry"
        exit 1
    fi
