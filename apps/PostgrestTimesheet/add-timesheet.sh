#!/bin/bash

#Note: set -e means: Exit immediately if a command exits with a non-zero status.
#remove if not desired
set -e

# use below if you need to use vim on a machine that is not already configured the way you like it
# When scripting use :rv chuboe_scipting.viminfo

# {{{ Context
# load the script name and path into variables
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")

## Bring chuboe.properties into context
#source $SC_SCRIPTPATH/chuboe.properties

# logging
SC_LOGFILE="$SC_SCRIPTPATH/LOGS/$SC_BASENAME."`date +%Y%m%d`_`date +%H%M%S`".log"
mkdir -p $SC_SCRIPTPATH/LOGS/

# }}}

# {{{ Options
# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line
# the colon after the letter specifies there should be text with the option

# Step #1 - set the variables in SC_OPTSTRING
SC_OPTSTRING="hc:t:a:d:D:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-h    Help"
            exit 0
            ;;
        c) SC_Customer=${OPTARG}
            ;;
        t) SC_Ticket=${OPTARG}
            ;;
        a) SC_Amount=${OPTARG}
            ;;
        d) SC_Desc=${OPTARG}
            ;;
        D) SC_Date=${OPTARG}
            ;;

        # below is an example of a parameter that takes as argument (note the colon after to p:)
        # change or delete as you deem appropriate
        #p) echo "You didn't overwrite the stock prefix did you? I don't know what to do with ${OPTARG}";;
    esac
done
# }}}

# {{{ Preprocessing
if [[ $SC_Date = "" ]]
then
    SC_Date=$(date +%Y-%m-%d)
fi

if [[ $SC_Customer = "" ]]
then
    echo "error: Customer required"
	exit 1
fi

if [[ $SC_Amount = "" ]]
then
    echo "error: Amount required"
	exit 1
fi

#echo Customer=$SC_Customer
#echo Ticket=$SC_Ticket
#echo Amount=$SC_Amount
#echo Description=$SC_Desc
#echo Date=$SC_Date
#}}}

## example of a conditional statement => https://linuxhandbook.com/if-else-bash/
## tmux/screen check only needed if performing something that needs to remain alive when accidentally disconnected from a remote server
#if [ "$TERM" = "screen" ] # {{{ TMUX Check
#then
#    echo Confirmed inside screen or tmux to preserve session if disconnected.
#else
#    echo Exiting... not running inside screen or tumx to preserve session if disconnected.
#    exit 1
#fi #}}}

# {{{ Logging
#echo "consider logging output to a log file, for example:"
#echo "$SC_SCRIPTNAME |& tee $SC_LOGFILE"
# "press enter" only needed if performing something destructive where you want to user to think before progressing
#read -p "press Enter to continue, or Ctrl+C to stop"
#If calling this script from another script, use "echo $'\n' | #####.sh" to bypass read }}}

# {{{ Add your code here!!!
eval curl http://www.someurl:3000/chuboe_timesheet_import?select=chuboe_timesheet_import_id -X POST -H \"Prefer: return=representation\" -H \"Content-Type: application/json\" -d \'{\"chuboe_bp_name\": \"$SC_Customer\", \"amt\": $SC_Amount, \"chuboe_timesheet_ticketno\": \"$SC_Ticket\", \"description\": \"$SC_Desc\", \"m_product_id\": 1000005, \"datetrx\": \"$SC_Date\", \"ad_client_id\": 1000000}\'
#}}}
