#!/bin/bash
#

usage()
{
cat << EOF

usage: $0

This script helps you launch the appropriate iDempiere Plug-Ins/components on a given server

OPTIONS:
    -h  Help
    -i  Install Plug-Ins
    -r  Active Plug-Ins (Providing Plug-In/s is/are alredy installed)
EOF
}

#pull in variables from properties file
#NOTE: all variables starting with CHUBOE_PROP... come from this file.
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

#initialize variables with default values - these values might be overwritten during the next section based on command options
IS_INSTALL_PLUGINS="Y"
IS_START_PLUGINS="N"
PLUGINS_SCAN_PATH="$CHUBOE_PROP_PLUGINS_SCAN_PATH"
CUSTOM_PLUGINS_PATH="$CHUBOE_PROP_CUSTOM_PLUGINS_PATH"
IDEMPIERE_USER="$CHUBOE_PROP_IDEMPIERE_OS_USER"
IDEMPIERE_PATH="$CHUBOE_PROP_IDEMPIERE_PATH"
CHUBOE_UTIL_HG="$CHUBOE_PROP_UTIL_HG_PATH"


# process the specified options
# the colon after the letter specifies there should be text with the option
# NOTE: include u because the script previously supported a -u OSUser
while getopts ":hir" OPTION
do
    case $OPTION in
        h)  usage
            exit 1;;

        i)  IS_INSTALL_PLUGINS="N";;

        r)  IS_START_PLUGINS="Y";;

        # Option error handling.
        \?) valid=0
            echo "HERE: An invalid option has been entered: $OPTARG"
            exit 1
            ;;

        :)  valid=0
            echo "HERE: The additional argument for option $OPTARG was omitted."
            exit 1
            ;;

    esac
done

# show variables to the user (debug)
echo "Install Plugins" $IS_INSTALL_PLUGINS
echo "Plugis start" $IS_START_PLUGINS
echo "Plugins Source Dir"=$PLUGINS_SCAN_PATH
echo "Target customization plugins dir"=$CUSTOM_PLUGINS_PATH
echo "iDempiere user"=$IDEMPIERE_USER
echo "iDempiere Path"=$IDEMPIERE_PATH
echo "HERE: Distro details:"
cat /etc/*-release

# Save plugins inventory in file.
sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> $IDEMPIERE_PATH/plugins-list.txt &"

# Change permission
sudo chmod + $SCRIPTPATH/*.sh

if [[ $IS_INSTALL_PLUGINS == "Y" ]]
then

    # Checking deploy-jar folder exist or not.
    if [ -d "$PLUGINS_SCAN_PATH" ]; then
        echo "$PLUGINS_SCAN_PATH Directory Exist"
    else
        echo "Please create Directory deploy-jar under $IDEMPIERE_PATH and copy your all jar in same folder."
        exit 0
    fi

    # Checking plugins locate or not in deploy-jar
    if ls $PLUGINS_SCAN_PATH/*.jar 1> /dev/null 2>&1; then
        echo "Found vailid plug-In in $PLUGINS_SCAN_PATH"
    else
        echo "Could not found any plug-In in $PLUGINS_SCAN_PATH"
        exit 0
    fi

    # Checking customization-jar folder exist or not.
    if [ -d "$CUSTOM_PLUGINS_PATH" ]; then
        echo "$CUSTOM_PLUGINS_PATH Directory Exist"
    else
        sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER mkdir $CUSTOM_PLUGINS_PATH
    fi


    if ps aux | grep java | grep $IDEMPIERE_PATH > /dev/null
    then
        echo "idempiere service is running"
    else
        echo "idempiere service is not running, So please start idempiere service and try again."
        exit 0
    fi


    #### Array Configuration Start ####
    plugins=$(ls $PLUGINS_SCAN_PATH/ | grep .jar)
    str="$plugins"
    delimiter=\n
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

    for plugins in "${array[@]}"
    do
        echo " "
        echo " "
        echo "********************************************"
        echo "We're Deploying: $plugins"

        PLUGIN_NAME=$(ls $PLUGINS_SCAN_PATH/ | grep "$plugins" | cut -d '_' -f 1 | sed 's/$/_/')
        START_LEVEL_PLUGIN=$(ls $PLUGINS_SCAN_PATH/ | grep "$plugins" | cut -d '_' -f 1)
        EXIST_PLUGIN_NAME=$(grep -n "$PLUGIN_NAME" $IDEMPIERE_PATH/plugins-list.txt)

        if [ ! -z "$EXIST_PLUGIN_NAME" ];
        then
            echo "Plugin $plugins exist..."

            sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> /tmp/plugins-list-exist-$PLUGIN_NAME.txt &"
            sleep 2
            EXIST_PLUGIN_ID=$(cat /tmp/plugins-list-exist-$PLUGIN_NAME.txt | grep $PLUGIN_NAME | cut -f 1)
            
            START_LEVEL=$(cat $SCRIPTPATH/logilite_plugins_startlevel.csv | grep $START_LEVEL_PLUGIN | cut -d ',' -f 2)
            
            echo "Plugin $EXIST_PLUGIN_ID ID of existing $plugins"

            sudo -u $IDEMPIERE_USER cp -r $PLUGINS_SCAN_PATH/$plugins $CUSTOM_PLUGINS_PATH/
            ./logilite_telnet_update.sh $CUSTOM_PLUGINS_PATH/$plugins $EXIST_PLUGIN_ID $START_LEVEL
            counter=$((counter + 1))

            echo "Plugin $plugins installed successfully."
            echo "********************************************"
            echo " "
            echo " "

        else

            echo "Plugin $plugins not exist..."

            sudo -u $IDEMPIERE_USER cp -r $PLUGINS_SCAN_PATH/$plugins $CUSTOM_PLUGINS_PATH/
            ./logilite_telnet_install.sh $CUSTOM_PLUGINS_PATH/$plugins
            sleep 1

            sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> /tmp/plugins-list-exist-$PLUGIN_NAME.txt &"
            sleep 2
            PLUGIN_ID=$(cat /tmp/plugins-list-exist-$PLUGIN_NAME.txt | grep $PLUGIN_NAME | cut -f 1)
            echo "Plugin $PLUGIN_ID ID of $PLUGIN_NAME"

            START_LEVEL=$(cat $SCRIPTPATH/logilite_plugins_startlevel.csv | grep $START_LEVEL_PLUGIN | cut -d ',' -f 2)
            
            ./logilite_telnet_set_bundlelevel.sh $PLUGIN_ID $START_LEVEL
            counter=$((counter + 1))

            echo "$plugins installed successfully."
            echo "********************************************"
            echo " "
            echo " "
        fi
    done
fi

if [[ $IS_INSTALL_PLUGINS == "Y" ]]
then
    echo "Here: Restarting iDempiere Service"
    sudo service idempiere restart
    echo "iDempiere Service Restarted Successfully"
    sleep 10
fi

if [[ $IS_START_PLUGINS == "Y" ]]
then
       
    PLUGINS_LIST=$(ls $PLUGINS_SCAN_PATH/ | grep .jar | cut -d '_' -f 1 | sed 's/$/_/')
    strp="$PLUGINS_LIST"
    delimiterp=\n
    strLenp=${#strp}
    dLenp=${#delimiterp}
    p=0
    wordLenp=0
    strPp=0
    array=()
    while [ $p -lt $strLenp ]; do
        if [ $delimiterp == '${strp:$p:$dLenp}' ]; then
            array+=(${strp:strPp:$wordLenp})
            strPp=$(( p + dLenp ))
            wordLenp=0
            p=$(( p + dLenp ))
        fi
        p=$(( p + 1 ))
        wordLenp=$(( wordLenp + 1 ))
    done
    array+=(${strp:strPp:$wordLenp})

    for plugunselement in "${array[@]}"
    do
        echo " "
        echo "********************************************"
        sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> /tmp/plugins-list-exist-"$plugunselement"-id.txt &"
        sleep 2
        JAR_BUNDLE_ID=$(cat /tmp/plugins-list-exist-"$plugunselement"-id.txt | grep $plugunselement | cut -f 1)
        echo "Update/Install Plugin ID"="$JAR_BUNDLE_ID"
        ./logilite_telnet_start.sh $JAR_BUNDLE_ID
        sleep 1
        
        sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> /tmp/plugins-list-exist-"$plugunselement"-status.txt &"
        sleep 2
        JAR_BUNDLE_STATUS=$(cat /tmp/plugins-list-exist-"$plugunselement"-status.txt | grep $plugunselement | cut -d " " -f 1 | cut -f 2)
        echo "Status of $plugunselement is"="$JAR_BUNDLE_STATUS"
        echo "********************************************"
        echo " "
    done

fi

if [[ $IS_INSTALL_PLUGINS == "Y" ]]
then
    # Remove plugins list and deployed jar from deploy-jar folder
    sudo rm -rf $PLUGINS_SCAN_PATH/*.jar /tmp/plugins*
    sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> $IDEMPIERE_PATH/plugins-list.txt &"

    # Create a backup of the iDempiere folder after deployed plugins
    cd $CHUBOE_UTIL_HG/utils/
    ./chuboe_hg_bindir.sh

    # Change idempiere-server folder permission to avoid any conflict.
    sudo chown -R $IDEMPIERE_USER:$IDEMPIERE_USER $IDEMPIERE_PATH

    echo "##############################################################################################"
    echo $counter "Plugins is deployed, Please verify plugins status in $IDEMPIERE_PATH/plugins-list.txt"
    echo "##############################################################################################"
fi