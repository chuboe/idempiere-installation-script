#!/bin/bash

#Bring chuboe.properties into context
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_untar_local.log"
ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
USER=$CHUBOE_PROP_DB_USERNAME

# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line
# the colon after the letter specifies there should be text with the option

# Step #1 - set the variables in OPTSTRING
OPTSTRING="hf:"

while getopts $OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-f    specify path to tar, either relative to $LOCALBACKDIR or absolute"
            echo "-h    Help"
            exit 0
            ;;

        f) LOCALBACKTAR=${OPTARG};; 
    esac
done

#Write to log to kick off 


echo LOGFILE="$LOGFILE" |& tee "$LOGFILE"
date |& tee "$LOGFILE" 
echo ADEMROOTDIR="$ADEMROOTDIR" |& tee "$LOGFILE"


cd $LOCALBACKDIR

mkdir latest/
rm latest/*

tar -xv $LOCALBACKTAR latest/ |&  tee "$LOGFILE"
