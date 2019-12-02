#!/bin/bash
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

PLUGINS_SCAN_PATH=$CHUBOE_PROP_PLUGINS_SCAN_PATH
CUSTOM_PLUGINS_PATH=$CHUBOE_PROP_CUSTOM_PLUGINS_PATH
IDEMPIERE_USER=$CHUBOE_PROP_IDEMPIERE_OS_USER
IDEMPIERE_PATH=$CHUBOE_PROP_IDEMPIERE_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH

echo "Plugins Source Dir"=$PLUGINS_SCAN_PATH
echo "Target customization plugins dir"=$CUSTOM_PLUGINS_PATH
echo "iDempiere user"=$IDEMPIERE_USER
echo "iDempiere Path"=$IDEMPIERE_PATH

if [ -d "$CUSTOM_PLUGINS_PATH" ]; then
    echo "Directory existq"
else
    sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER mkdir $CUSTOM_PLUGINS_PATH
fi

#### Array Configuration Start ####
plugins=$(ls $PLUGINS_SCAN_PATH/ | grep .jar) # Save Plgins list in variable
str="$plugins" # take plugins list as string
delimiter=\n # define delimiter for go next plugins 
strLen=${#str}
counter=0
dLen=${#delimiter}
i=0
wordLen=0
strP=0
array=()
while [ $i -lt $strLen ]; do
    if [ $delimiter == '${str:$i:$dLen}' ]; then
        array+=(${str:strP:$wordLen})
        strP=$(( i + dLen ))
        wordLen=0
        i=$(( i + dLen ))
    fi
    i=$(( i + 1 ))
    wordLen=$(( wordLen + 1 ))
done
array+=(${str:strP:$wordLen})
declare -p array
#### Array Configuration End ####

# Check if array empty then exit script
if [ ${#array[@]} -eq 0 ]; then
    echo "Plugins not found in $PLUGINS_SCAN_PATH"
    exit
fi
# Install Plugins
for element in "${array[@]}"
do
    sudo -u $IDEMPIERE_USER mv $PLUGINS_SCAN_PATH/$element $CUSTOM_PLUGINS_PATH/
    ./chuboe_osgi_install.sh $CUSTOM_PLUGINS_PATH/$element
    sleep 2
    counter=$((counter + 1))
done

sudo chown -R $IDEMPIERE_USER:$IDEMPIERE_USER $IDEMPIERE_PATH

# Restart iDempiere service
echo "Here: Restarting iDempiere Service"
sudo service idempiere restart
echo "iDempiere Service Restarted Successfully"

Store all plugins status in plugin-list.txt
cd $CHUBOE_UTIL_HG/utils/
sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> $IDEMPIERE_PATH/plugins-list.txt &"

# create a backup of the iDempiere folder after deployed plugins
cd $CHUBOE_UTIL_HG/utils/
./chuboe_hg_bindir.sh

echo "##############################################################################################"
echo $counter "Plugins is deployed, Please verify plugins status in $IDEMPIERE_PATH/plugins-list.txt"
echo "##############################################################################################"