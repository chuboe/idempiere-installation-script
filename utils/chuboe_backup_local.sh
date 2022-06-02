#!/bin/bash
set -e

#{{{ Context
#Bring chuboe.properties into context
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
source $SC_SCRIPTPATH/chuboe.properties

SC_LOGFILE="$SC_SCRIPTPATH/LOGS/$SC_BASENAME."`date +%Y%m%d`_`date +%H%M%S`".log"
SC_ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
SC_CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
SC_CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
SC_LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
SC_USER=$CHUBOE_PROP_DB_USERNAME
SC_ADDPG="-h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT"
SC_DATABASE=$CHUBOE_PROP_DB_NAME
SC_IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
SC_BACKUP_TAR="ExpDatDir_"`date +%Y%m%d`_`date +%H%M%S`".tar"
# You may update the number of cores used from default below
SC_BACKUP_RESTORE_JOBS=$CHUBOE_PROP_BACKUP_RESTORE_JOBS
#}}}

#{{{ Options
# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line
# the colon after the letter specifies there should be text with the option

# Step #1 - set the variables in SC_OPTSTRING
SC_OPTSTRING="hp:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-h    Help"
            exit 0
            ;;

        p) echo "You didn't overwrite the stock prefix did you? I don't know what to do with ${OPTARG}";;
    esac
done
#}}}

#{{{ Logging
echo "Be sure to tee to a log file, for example:"
echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
read -p "press Enter to continue, or Ctrl+C to stop" 
#REMEMBER when calling these scripts from other scripts use the following to bypass the read prompt
#echo $'\n' | ./chuboe_backup_local.sh 
#}}}

cd $SC_LOCALBACKDIR
mkdir -p latest/
mkdir -p archive/
rm -f latest/*

pg_dump $SC_ADDPG -vU $SC_USER $SC_DATABASE -Fd -j $SC_BACKUP_RESTORE_JOBS -f latest

tar -cvf archive/$SC_BACKUP_TAR latest/*
