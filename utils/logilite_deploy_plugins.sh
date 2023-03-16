#!/bin/bash
#

usage()
{
cat << EOF

usage: $0

This script helps you launch the appropriate iDempiere Plug-Ins/components on a given server

OPTIONS:
    -h  Help
    -I  (1) No Install/Update plug-ins (2) Start plug-ins (3) Restart iDempiere
    -S  (1) Install/Update plug-ins (2) Not Start plug-ins (3) Restart iDempiere
    -R  (1) Install/Update plug-ins (2) Start plug-ins (3) No Restart iDempiere
    -m  Also installed/Update plugins, which is already installed on server.
    -D  Will not delete source jar.
    -d  Delay for plugins with large pack ins
EOF
}

echo "You are about to update your system - you have 10 seconds to press ctrl+c to stop this script"
sleep 10

#pull in variables from properties file
#NOTE: all variables starting with CHUBOE_PROP... come from this file.
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
source $SCRIPTPATH/chuboe.properties

#initialize variables with default values - these values might be overwritten during the next section based on command options
IS_INSTALL_PLUGINS="Y"
IS_START_PLUGINS="Y"
IS_ID_RESTART="Y"
SKIP_DEPLOYED_PG="Y"
IS_DELETE_FROM_SCAN="Y"
PLUGINS_SCAN_PATH="$CHUBOE_PROP_DEPLOY_PLUGINS_PATH"
CUSTOM_PLUGINS_PATH="$CHUBOE_PROP_CUSTOM_PLUGINS_PATH"
IDEMPIERE_USER="$CHUBOE_PROP_IDEMPIERE_OS_USER"
IDEMPIERE_PATH="$CHUBOE_PROP_IDEMPIERE_PATH"
CHUBOE_UTIL_HG="$CHUBOE_PROP_UTIL_HG_PATH"
DELAY_FOR_LARGE_PACKIN=5

cd $CHUBOE_UTIL_HG/utils/

# check to see if test server
if [[ $CHUBOE_PROP_IS_TEST_ENV == "N" ]]; then
    echo "HERE: Not a test environment - Creating a backup of the iDempiere directory!"
    # Create a backup of the iDempiere folder before deployed plugins
    ./chuboe_hg_bindir.sh
fi


# process the specified options
# the colon after the letter specifies there should be text with the option
# NOTE: include u because the script previously supported a -u OSUser
while getopts ":hISRmDd:" OPTION
do
    case $OPTION in
        h)  usage
            exit 1;;

        I)  IS_INSTALL_PLUGINS="N";;

        R)  IS_START_PLUGINS="N";;

        S)  IS_ID_RESTART="N";;

        m)  SKIP_DEPLOYED_PG="N";;

        D)  IS_DELETE_FROM_SCAN="N";;

        d)  DELAY_FOR_LARGE_PACKIN=$OPTARG;;

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

# Wait for a moment to generate plugins-list.txt inventory file.
sleep 10

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

    # make sure all plugins files are owned by iDempiere before we start
    sudo chown -R $IDEMPIERE_USER:$IDEMPIERE_USER $PLUGINS_SCAN_PATH

    # Checking customization-jar folder exist or not.
    if [ -d "$CUSTOM_PLUGINS_PATH" ]; then
        echo "$CUSTOM_PLUGINS_PATH Directory Exist"
    else
        sudo -u $IDEMPIERE_USER mkdir $CUSTOM_PLUGINS_PATH
    fi


    if ps aux | grep java | grep $IDEMPIERE_PATH > /dev/null
    then
        echo "idempiere service is running"
    else
        echo "idempiere service is not running, So please start idempiere service and try again."
        exit 0
    fi

    # Wait for Plugin ID.
    function_wait() {
        MAXITERATIONS=6
        STATUSTEST=0
        ITERATIONS=0
        while [ $STATUSTEST -eq 0 ] ; do
            sleep 2
            tail -n 90 $UPDATE_PLUGIN_FILE | grep -q '.*osgi> Connection closed by foreign host.*' && STATUSTEST=1
            echo -n "."
            ITERATIONS=`expr $ITERATIONS + 1`
            if [ $ITERATIONS -gt $MAXITERATIONS ]
                then
                break
            fi
        done
        echo
    }



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
    ScanPlugInArray=()
    while [ $i -lt $strLen ]; do
        if [ $delimiter == '${str:$i:$dLen}' ]; then
            ScanPlugInArray+=(${str:strP:$wordLen})
            strP=$(( i + dLen ))
            wordLen=0
            i=$(( i + dLen ))
        fi
        i=$(( i + 1 ))
        wordLen=$(( wordLen + 1 ))
    done    
    ScanPlugInArray+=(${str:strP:$wordLen})

    echo "Scan Plug-In Jar List:" ${ScanPlugInArray[*]}

    for plugins in "${ScanPlugInArray[@]}"
    do
        echo " "
        echo " "
        echo "********************************************"

        PLUGIN_NAME=$(ls $PLUGINS_SCAN_PATH/ | grep "$plugins" | cut -d '_' -f 1 | sed 's/$/_/')
        PLUGIN_NAME_WITHOUT_VERSION=$(ls $PLUGINS_SCAN_PATH/ | grep "$plugins" | cut -d '_' -f 1)
        PLUGIN_NAME_WITH_VERSION=$(ls $PLUGINS_SCAN_PATH/ | grep "$plugins" | sed 's/.\{4\}$//')
        UPDATE_PLUGIN_FILE="/tmp/plugins-list-exist-$PLUGIN_NAME.txt"

        # Checking, Same version plugin already installed or not,
        # If already installed same verseion plugin then skip and continue with next one.
        if [[ $SKIP_DEPLOYED_PG == "Y" ]]
        then          
            CHECKING_PLUGIN=
            checkingplugin() {
                CHECKINGPLUGINSTRING=$(grep -n "$PLUGIN_NAME_WITH_VERSION" $IDEMPIERE_PATH/plugins-list.txt)
                CHECKING_PLUGIN=$?
            }

            # Fatching deployable plugin version & deployed plugin version as variable.
            FATCHING_PLUGIN_VERSION=$(ls $PLUGINS_SCAN_PATH/ | grep "$plugins" |  cut -d '_' -f 2 | sed 's/.\{4\}$//')
            sleep 2
            FATCHING_DEPLOYED_PLUGIN_VERSION=$(grep -n "$PLUGIN_NAME" $IDEMPIERE_PATH/plugins-list.txt | cut -d '_' -f 2 | awk '{$1=$1;print}')
            sleep 2
            FATCHING_MILTIPLE_UNDERSCORE=$(echo "$plugins" | awk '{A=gsub(/_/,X,$0)}END {print A}')
            sleep 2

            echo "Plug-In Name : $plugins"
            echo "Scan Plug-In Version :     $FATCHING_PLUGIN_VERSION"

            if [ -z "$FATCHING_DEPLOYED_PLUGIN_VERSION" ]
            then
                echo "Deployed Plug-In Version : Not exist "
            else
                echo "Deployed Plug-In Version : $FATCHING_DEPLOYED_PLUGIN_VERSION"
            fi

            checkingplugin            
            if [ $CHECKING_PLUGIN -eq 0 ]; then
                echo "Skip deployment as already exist : $plugins"
                continue
            fi

            # Checking More then one underscore, if found then skip deployment for same Jar.
            if [[ 2 -eq $FATCHING_MILTIPLE_UNDERSCORE ]]; then
                echo "More then one underscore not suppoted by deployment script: $plugins"
                continue
            fi

            if [ "$(printf '%s\n' "$FATCHING_PLUGIN_VERSION" "$FATCHING_DEPLOYED_PLUGIN_VERSION" | sort -V | head -n1)" = "$FATCHING_PLUGIN_VERSION" ]; then
                echo "Skip deployment latest/higher version already deployed : $plugins"
                continue
            fi
        fi

        # Checking  plugin already installed or not,
        # If already installed plugin with older version then update that plugin or plugin is not installed on server then it will going to install.
        PlUGINSTATUS=
        getpluginstatus() {
            PLUGINSTATUSSTRING=$(grep -n "$PLUGIN_NAME" $IDEMPIERE_PATH/plugins-list.txt)
            PlUGINSTATUS=$?
        }

        getpluginstatus
        if [ $PlUGINSTATUS -eq 0 ];
        then
            echo "Updating :  $plugins"

            EXIST_PLUGIN_ID=$(cat $IDEMPIERE_PATH/plugins-list.txt | grep $PLUGIN_NAME | cut -f 1)
            sleep 1

            # Checking logilite_plugins_startlevel.csv file exist or not.
            Startlevel_CSV="$SCRIPTPATH/logilite_plugins_startlevel.csv"
            if [ -f "$Startlevel_CSV" ]; then
                START_LEVEL=$(cat $SCRIPTPATH/logilite_plugins_startlevel.csv | grep $PLUGIN_NAME_WITHOUT_VERSION | cut -d ',' -f 2)
            fi
            
            echo "Plugin ID :  $EXIST_PLUGIN_ID"

            sudo -u $IDEMPIERE_USER cp -r $PLUGINS_SCAN_PATH/$plugins $CUSTOM_PLUGINS_PATH/
            ./logilite_telnet_update.sh $CUSTOM_PLUGINS_PATH/$plugins $EXIST_PLUGIN_ID $START_LEVEL

            counter=$((counter + 1))

            InstallUpdatePlugInArray+=( $plugins )

            echo "$plugins updated successfully."
            echo "********************************************"
            echo " "
            echo " "

        else

            echo "Installing :  $plugins"
            
            # Installing plugin
            sudo -u $IDEMPIERE_USER cp -r $PLUGINS_SCAN_PATH/$plugins $CUSTOM_PLUGINS_PATH/
            ./logilite_telnet_install.sh $CUSTOM_PLUGINS_PATH/$plugins > $UPDATE_PLUGIN_FILE
            sleep 2
            
            # Waiting for Plugin ID.
            function_wait

            # Faching Plugin ID in variable.
            PLUGIN_ID=$(cat $UPDATE_PLUGIN_FILE | grep "Bundle ID" | cut -d ':' -f 2 | awk '{$1=$1;print}')
            sleep 1
            
            echo "Plugin ID :  $PLUGIN_ID"

            # Checking logilite_plugins_startlevel.csv file exist or not..
            Startlevel_CSV="$SCRIPTPATH/logilite_plugins_startlevel.csv"
            if [ -f "$Startlevel_CSV" ]; then
                START_LEVEL=$(cat $SCRIPTPATH/logilite_plugins_startlevel.csv | grep $PLUGIN_NAME_WITHOUT_VERSION | cut -d ',' -f 2)
            fi
            
            # Changing plugins startlevel.
            ./logilite_telnet_set_bundlelevel.sh $PLUGIN_ID $START_LEVEL
            counter=$((counter + 1))

            InstallUpdatePlugInArray+=( $plugins )

            echo "$plugins installed successfully."
            echo "********************************************"
            echo " "
            echo " "
        fi
        echo sleeping for $DELAY_FOR_LARGE_PACKIN seconds
        sleep $DELAY_FOR_LARGE_PACKIN
    done
fi

if [[ $IS_ID_RESTART == "Y" ]]
then
    echo "Here: Restarting iDempiere Service"
    sudo service idempiere restart
    echo "iDempiere Service Restarted Successfully"
    sleep 10
fi


# Saving install/Update plugins in file.
UPDATE_PLUGIN_FILE="/tmp/plugins-list-exist-id.txt"
sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> $UPDATE_PLUGIN_FILE &"

# Waiting for Plugin ID.
function_wait

if [[ $IS_START_PLUGINS == "Y" ]]
then

    # Staring only Install/Update plugins
    for StartInstallUpdatePlugIn in "${InstallUpdatePlugInArray[@]}"
    do
        echo " "
        echo "********************************************"
        PLUGIN_NAME=$(echo "$StartInstallUpdatePlugIn" | cut -d '_' -f 1 | sed 's/$/_/')
        JAR_BUNDLE_ID=$(cat $UPDATE_PLUGIN_FILE | grep $PLUGIN_NAME | cut -f 1)
        echo "Update/Install Plugin ID"="$JAR_BUNDLE_ID"
        ./logilite_telnet_start.sh $JAR_BUNDLE_ID
        echo sleeping for $DELAY_FOR_LARGE_PACKIN seconds
        sleep $DELAY_FOR_LARGE_PACKIN
    done


    # Faching plugins status
    UPDATE_PLUGIN_FILE="/tmp/plugins-list-exist-status.txt"
    sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> $UPDATE_PLUGIN_FILE &"

    # Waiting for Plugin ID.
    function_wait

    # Geting status of Install/Update plugins
    for StatusInstallUpdatePlugIn in "${InstallUpdatePlugInArray[@]}"
    do
        PLUGIN_NAME=$(echo "$StatusInstallUpdatePlugIn" | cut -d '_' -f 1)
        JAR_BUNDLE_STATUS=$(cat $UPDATE_PLUGIN_FILE | grep $PLUGIN_NAME | cut -d " " -f 1 | cut -f 2)
        echo "Status of $PLUGIN_NAME is"="$JAR_BUNDLE_STATUS"
        echo "********************************************"
        echo " "
    done


fi

if [[ $IS_INSTALL_PLUGINS == "Y" ]]
then
    # Remove plugins list and deployed jar from deploy-jar folder
    if [[ $IS_DELETE_FROM_SCAN == "Y" ]]
    then
        sudo rm -rf $PLUGINS_SCAN_PATH/*.jar
    fi
    
    sudo rm -rf /tmp/plugins*
    sudo su $IDEMPIERE_USER -c "./chuboe_osgi_ss.sh &> $IDEMPIERE_PATH/plugins-list.txt &"
    
    # wait 10 seconds for the deployment to finish before taking a backup
    sleep 10

    cd $CHUBOE_UTIL_HG/utils/
    
    # check to see if test server
    # Create a backup of the iDempiere folder after deployed plugins
    if [[ $CHUBOE_PROP_IS_TEST_ENV == "N" ]]; then
        echo "HERE: Not a test environment - Creating a backup of the iDempiere directory!"
        # Create a backup of the iDempiere folder before deployed plugins
        ./chuboe_hg_bindir.sh
    fi
    # Change idempiere-server folder permission to avoid any conflict.
    # CHUCK: this should not be necessary and it is potentially dangerous in that it can mask issues.
    #sudo chown -R $IDEMPIERE_USER:$IDEMPIERE_USER $IDEMPIERE_PATH

    echo "##############################################################################################"
    echo $counter "Plugins is deployed, Please verify plugins status in $IDEMPIERE_PATH/plugins-list.txt"
    echo "##############################################################################################"
fi
