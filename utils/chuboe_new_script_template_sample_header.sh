#!/bin/bash

#Note: set -e means: Exit immediately if a command exits with a non-zero status.
#remove if not desired
set -e

# use below if you need to use vim on a machine that is not already configured the way you like it
# When scripting use :rv chuboe_scipting.viminfo

# use this function as a way to exit if assumptions are not met or error conditions are found
# see below example for how to pass in the error message
function graceful_exit
{
      echo -e "Exiting due to an error occuring at $(TZ=US/Eastern date '+%m/%d/%Y %H:%M:%S EST.')\n" | tee -a $LOG_FILE
      echo -e "Some results before the error may have been logged to $LOG_FILE\n"
      echo -e "Here is the error message: $1\n"
      exit 1
}

# {{{ Context
# load os details into variables
SC_OS=$(. /etc/os-release && echo "$ID")
SC_OS_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")

# load the script name and path into variables
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")

cd $SC_SCRIPTPATH || graceful_exit "could not cd to desired path"

## Alternate for future reference - get the directory where the script is located
#SC_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
## Change to the script's directory
#cd "$SC_SCRIPT_DIR" || graceful_exit "could not cd to desired path"

# logging
mkdir -p $SC_SCRIPTPATH/LOGS/
SC_LOGFILE="$SC_SCRIPTPATH/LOGS/$SC_BASENAME."`date +%Y%m%d`_`date +%H%M%S`".log"

# this section only needed if writing a script for idempiere management - otherwise, delete/comment
# Bring chuboe.properties into context
source $SC_SCRIPTPATH/chuboe.properties || graceful_exit "could not source chuboe.properties"
SC_ADEMROOTDIR=$CHUBOE_PROP_IDEMPIERE_PATH
SC_UTIL=$CHUBOE_PROP_UTIL_PATH
SC_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
SC_LOCALBACKDIR=$CHUBOE_PROP_BACKUP_LOCAL_PATH
SC_USER=$CHUBOE_PROP_DB_USERNAME
# }}}

# {{{ place default values and pre-validation here - to be overridden by below cli options/optargs
# add stuff here if needed
# }}}

# {{{ Options/optargs
# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line

# Step #1 - set the variables in SC_OPTSTRING
# the colon after the letter specifies there should be text with the option
SC_OPTSTRING="hp:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-h    Help"
            echo "-p    Example p that should be changed"
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
TERM_CHECK=${TERM:0:4} #grab the first 4 char of variable
if [[ "$TERM_CHECK" = "scre" ]] || [[ "$TERM_CHECK" = "tmux" ]] # {{{ TMUX Check
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

# {{{ place post-validation here
# add stuff here if needed
# }}}

# {{{ Add your code here!!!
# add something great...
#}}}
