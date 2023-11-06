#!/bin/bash

# use this function as a way to exit if assumptions are not met or error conditions are found
function graceful_exit
{
      echo -e "Exiting due to an error occuring at $(TZ=US/Eastern date '+%m/%d/%Y %H:%M:%S EST.')\n" | tee -a $LOG_FILE
      echo -e "Some results before the error may have been logged to $LOG_FILE\n"
      echo -e "Here is the error message: $1\n"
      exit 1
}

# {{{ Context
# load the script name and path into variables
SC_SCRIPTNAME=$(readlink -f "$0")
SC_SCRIPTPATH=$(dirname "$SC_SCRIPTNAME")
SC_BASENAME=$(basename "$0")

cd $SC_SCRIPTPATH || graceful_exit "could not cd to desired path"
# }}}

# {{{ default values and pre-validations

# if not specified by the -s option below, set the swap to the same as RAM
TOTAL_MEMORY=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 / 1024)}')
echo "total memory in system MB="$TOTAL_MEMORY
TOTAL_MEMORY_W_LABEL=$TOTAL_MEMORY"M"
echo $TOTAL_MEMORY_W_LABEL

# check if user has sudo ability
# TODO:

# }}}

# {{{ Options
# check for command line properties
# Special thanks to https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
# variables will be processed in the order they appear on the command line
# the colon after the letter specifies there should be text with the option

# Step #1 - set the variables in SC_OPTSTRING
SC_OPTSTRING="hs:"

while getopts $SC_OPTSTRING option; do
    case "${option}" in

        # Step #2 - handle variables
        h) echo "Usage:"
            echo "-h    Help"
            echo "-s    swap size with label - example: 5G"
            exit 0
            ;;

        # specify the swapsize - example: 5G
        s) TOTAL_MEMORY_W_LABEL=${OPTARG};;
    esac
done
# }}}

# {{{ post-validations

# check if memory value is not null
# TODO

# check if enough space on hard drive
# TODO

# }}}

# {{{ Create swap - reference: https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04

# check if swap already exists; if yes, exit

# create swap file
sudo fallocate -l $TOTAL_MEMORY_W_LABEL /swapfile

# enable swap file
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# tune swap settings
sudo sysctl vm.swappiness=10
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl vm.vfs_cache_pressure=50
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf

#}}}

