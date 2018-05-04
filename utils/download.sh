#!/bin/bash

# Arguments:
#  1 - HOSTPATH including trailing /
#  2 - Filename
#  3 - local path prefix including trailing /
#  4 - (Optional) Jenkins Auth command
    
    # preprocess the URL to ensure no double forward slash exists except for ://
    # remove double slashes = sed s#//*#/#g
    # add back :// = sed s#:/#://#g
    HOSTPATH_URL=$(echo $1 | sed s#//*#/#g | sed s#:/#://#g)
    
    # wget --unlink doesn't remove the file, must use rm
    # Must remove the file because if it exists in a corrupted state wget will not fix it, instead it will make a new file named .1
    if [ -e $3/$2 ]; then { rm $3/$2 ; } fi
    if [ -e $3/$2.md5 ]; then { rm $3/$2.md5 ; } fi

    # add -nv if you do not want to see detailed downloading progress in output.txt
    echo "DOWNLOAD FILE: wget $4 $HOSTPATH_URL$2 -P $3 2>&1"
    wget $4 $HOSTPATH_URL$2 -P $3 2>&1
    if [ $? -ne 0 ]; then { echo "HERE: Can't download $HOSTPATH_URL$2"; exit 1; } fi

    # Check to see if md5 exists. If so, downloaded md5 file
    echo "DOWNLOAD MD5: wget $4 $HOSTPATH_URL$2.md5 -P $3 2>&1"
    wget $4 $HOSTPATH_URL$2.md5 -P $3 2>&1
    if [ $? -ne 0 ]; then { echo "HERE: Can't download $HOSTPATH_URL$2.md5. This is not a fatal error, but cannot verify download."; exit 0; } fi

    # Check download against md5
    # NOTE: use the md5 command to create a test file. Note: use the same file name with a .md5 suffix.
    #     Example: md5 s3cmd-1.6.1.tar.gz > s3cmd-1.6.1.tar.gz.md5
    cd $3
    md5sum -c $2.md5
    if [ $? -ne 0 ]; then { echo "HERE: MD5 sum of $3/$2 failed"; exit 1; } fi
