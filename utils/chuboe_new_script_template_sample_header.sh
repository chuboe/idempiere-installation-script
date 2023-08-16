#!/bin/bash

#Note: set -e means: Exit immediately if a command exits with a non-zero status.
#remove if not desired
set -e

#When scripting use :rv chuboe_scipting.viminfo

# {{{ Context
# load the script name and path into variables
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")

# Bring chuboe.properties into context
source $SC_SCRIPTPATH/chuboe.properties

# logging
SC_LOGFILE="$SC_SCRIPTPATH/LOGS/$SC_BASENAME."`date +%Y%m%d`_`date +%H%M%S`".log"

# only needed if writing a script for idempiere management - otherwise, delete/comment
SC_ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
SC_UTIL=$CHUBOE_PROP_UTIL_PATH
SC_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
SC_LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
SC_USER=$CHUBOE_PROP_DB_USERNAME
# }}}

# {{{ Options
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

        # below is an example of a parameter that takes as argument (note the colon after to p:)
        # change or delete as you deem appropriate
        p) echo "You didn't overwrite the stock prefix did you? I don't know what to do with ${OPTARG}";;
    esac
done
# }}}

# example of a conditional statement => https://linuxhandbook.com/if-else-bash/
# tmux/screen check only needed if performing something that needs to remain alive when accidentally disconnected from a remote server
if [ "$TERM" = "screen" ] # {{{ TMUX Check
then
    echo Confirmed inside screen or tmux to preserve session if disconnected.
else
    echo Exiting... not running inside screen or tumx to preserve session if disconnected.
    exit 1
fi #}}}

# {{{ Logging
echo "consider logging output to a log file, for example:"
echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
# "press enter" only needed if performing something destructive where you want to user to think before progressing
read -p "press Enter to continue, or Ctrl+C to stop" 
#If calling this script from another script, use "echo $'\n' | #####.sh" to bypass read }}}
