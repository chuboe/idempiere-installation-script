#!/bin/bash

set -e

#Bring chuboe.properties into context
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")
source $SC_SCRIPTPATH/chuboe.properties

SC_LOGFILE="$CHUBOE_PROP_LOG_PATH/chuboe_untar_local.log"
SC_ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
SC_CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
SC_CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
SC_LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
SC_USER=$CHUBOE_PROP_DB_USERNAME

# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line
# the colon after the letter specifies there should be text with the option

# Step #1 - set the variables in OPTSTRING
SC_OPTSTRING="hf:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-f    specify path to tar, either relative to $SC_LOCALBACKDIR or absolute"
            echo "-h    Help"
            exit 0
            ;;

        f) SC_UNTAR_PATH=${OPTARG};; 
    esac
done

echo "Be sure to tee to a log file, for example:"
echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
read -p "press Enter to continue, or Ctrl+C to stop" 
#REMEMBER when calling these scripts from other scripts use "echo $'\n' | #####.sh" to bypass read

cd $SC_LOCALBACKDIR

mkdir -pv latest/
rm latest/* || echo No latest Folder

tar -xvf $SC_UNTAR_PATH latest/ 
