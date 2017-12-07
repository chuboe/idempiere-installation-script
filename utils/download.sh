#!/bin/bash

# Arguments:
#  1 - HOSTPATH including trailing /
#  2 - Filename
#  3 - local path prefix including trailing /
#  4 - (Optional) Jenkins Auth command
    # wget --unlink doesn't remove the file, must use rm
    # Must remove the file because if it exists in a corrupted state wget will not fix it, instead it will make a new file named .1
    if [ -e $3/$2 ]; then { rm $3/$2 ; } fi
    # Remove the -nv if you want to see detailed downloading progress in output.txt
    wget -nv $4 $1$2 -P $3 2>&1
    if [ $? -ne 0 ]; then { echo "HERE: Can't download $1$2"; exit 1; } fi

    # Need to automatically check for MD5 file here...
