#!/bin/bash

# Release Details
#{{{
# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
# idempiere_install_script_master_linux.sh
# 1.0 initial release
# 1.1 run iDempiere as service
# 1.2 added remote desktop development environment
# 1.3 added better error checking and user handling
# 1.4 added better user instruction (specifically for s3 backup)
# 1.5 run iDempiere service as idempiere user
# 1.6 added hot_standby replication, user home directory check, and removed sleep statement from backup command
# 1.7 added JVM and PostgreSQL performance enhancements when installing on dedicated boxes.
# 1.8 Added ActiveMQ JMS installation script
# 1.9 refactored to not use local user and install chuboe_utils beside idempiere - not inside
# 2.0 Removed ability to pull from sf.net - always pull from a Jenkens server.
#     Pull iDempiere from any jenkins server/project
#     Install directly on AWS RDS
#     Created parameter file for advanced installation
#     Added ability to install a services only server
#     Change the DB name from "idempiere" to something more secure
#     Change the DB username from "adempiere" to something more secure
#     Install from development branch (3.0)
#     Improved usage of support scripts (backup, restore, upgrade, etc...)
#     Added ability to launch a new WebUI server without initializing the database - used when adding a new server to the loadbalanced WebUI farm or when replacing the existing WebUI server.
# 2.1 Install the latest version of s3cmd
# 2.2 Support ubuntu 16.04 LTS
# 2.2.1 Added notes for key concepts "Key Concept"
# 2.3 Support for iDempiere 4.1
# 2.4 Moved download to beginning, added Zip and GZip archive testing in addition to MD5
# 2.4.1 Changed to delete previously downloaded files if they exist for the smaller installation files.  Larger downloaded files (.zip, .gz) will be verified, and if
#       verification fails they will be deleted and re-downloaded
# 2.5 Support for iDempiere 5.1
# 2.6 Support for 18.04 and iDempiere 6.2
# 2.6.1 Added support for alternate properties file passed in as parameter
# planned changes
#   install s3cmd from apt (not file)
#   install pgadmin (in addition to phppgadmin)
#   postgresql 12
#   openjdk 11 (from apt - not custom ppa)
#
#}}}

# Usage help
# {{{
usage()
{
cat << EOF

usage: $0

This script helps you launch the appropriate
iDempiere components on a given server

OPTIONS:
    -h  Help
    -s  Only run services on this machine.
        services like accounting and workflow
    -p  No install postgresql - provide the
        IP for the postgresql server
    -e  Move the postgresql files
        to EBS - provide the drive name
    -i  No install iDempiere (DB only)
    -I  Do not initialize iDempiere database - used when adding or replacine an iDempiere WebUI/App server.
    -P  DB password
    -l  Launch iDempiere as service
    -v  Specify iDempiere version - defaults to 6.2
    -J  Specify Jenkins URL - See chuboe.properties.orig for default
    -j  Specify Jenkins project name - See chuboe.properties.orig for default
    -b  Specify Jenkins build number - See chuboe.properties.orig for default
    -a  Specify an alternate properties file
    -r  Add Hot_Standby Replication - a parameter of "Master" indicates the db will be a Master. A parameter for a URL should point to a master and therefore will make this db a Backup

Outstanding actions:
* Add a -t flag to allow for giving a server a specific name
     - update the $PS1 command prompt with new name
     - append the tag to the end of the database name: i.e. -t dev-01 would create idempiere-dev-01
     - test all scripts to make sure they work with the different datbase name
* Create flag or convention to change username and passwords for system generated entries (i.e. MaxSuperUser and MaxSystem)
     - add this information to the idempiere feedback file
* Review the output formatting of the idempiere feedback file - make sure it is consistent and looks good.
* Create option to specify password during installation - as opposed to as a command line option
* When Replication is turned on, created and set archive files to appropriate place.
    * create an option to move archive to remove drive as well. This is more important than the actual data drive. This drive should be fast.
* Create drive options for WAL. Move logs to different location - not on DB or WAL drive. Can be local system drive.
* Create a parameter file that contains the IP of the db server for use in other scripts - like backup
* Attachments
    - Create /opt/idempiere-attachments folder chown idempiere user/group
    - Create record in iDempiere (as system client) to enable using the above folder (sql) (Attachment Storage clientInfo)
    - Create drive option/flag for attachments to store off the actual server
* Enable PG_Statements by default when installing the DB alone
* Add ability to read idempiereEnv.properties
    - ACTION=$(grep -i 'SOME_PROPERTY' $PATH_TO_FILE  | cut -f2 -d'=')
    - source: http://www.linuxquestions.org/questions/linux-newbie-8/reading-a-property-file-through-shell-script-906482/
* Create /opt/idempiere-attachment/ and /opt-idempiere-archive/ folders so that users can have an easy place to store external files.

EOF
}
# }}}

# Initialize variables
# {{{
#pull in variables from properties file
#NOTE: all variables starting with CHUBOE_PROP... come from this file.
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")

VARIABLE_FLAG_LIST=":hsp:e:iP:lDj:J:b:v:a:r:Iu:"

cp $SCRIPTPATH/utils/chuboe.properties.orig $SCRIPTPATH/utils/chuboe.properties
source $SCRIPTPATH/utils/chuboe.properties

#check to see if the properties file specifies an alternative properties file
#this is the first property merge of two.
if [[ $CHUBOE_PROP_DEFAULT_PROPERTY_PATH != "NONE" ]]
then
    #load the variables
    #assume utils directory as default. Default can specify an absolute path if needed.
    cd $SCRIPTPATH/utils/
    echo HERE: source $CHUBOE_PROP_DEFAULT_PROPERTY_PATH
    source $CHUBOE_PROP_DEFAULT_PROPERTY_PATH
    #merge new variables back to chuboe.properties file
    awk -F= '!a[$1]++' $CHUBOE_PROP_DEFAULT_PROPERTY_PATH $SCRIPTPATH/utils/chuboe.properties > $SCRIPTPATH/utils/chuboe.properties.tmp
    mv $SCRIPTPATH/utils/chuboe.properties.tmp $SCRIPTPATH/utils/chuboe.properties
fi

# read alternative flag
while getopts "$VARIABLE_FLAG_LIST" OPTION
do
    case $OPTION in
        a)  #alternate properties file
            ALTERNATE_PROP_FILE=$OPTARG;;
    esac
done

# Reset getopts for next variable flag read
OPTIND=1

#update variables based on property file passed in.
#this is the second property merge of two.
if [[ $ALTERNATE_PROP_FILE != "NONE" ]]
then

	if [ ! -f $ALTERNATE_PROP_FILE ]; then
    	#if alternate file not exist then check is it in script location
		if [ -f $SCRIPTPATH/utils/$ALTERNATE_PROP_FILE ]; then
		ALTERNATE_PROP_FILE=$SCRIPTPATH/utils/$ALTERNATE_PROP_FILE
	else
		echo "$ALTERNATE_PROP_FILE does not exists"
	fi
    fi
    #load the variables
    source $ALTERNATE_PROP_FILE
    #merge new variables back to chuboe.properties file
    awk -F= '!a[$1]++' $ALTERNATE_PROP_FILE $SCRIPTPATH/utils/chuboe.properties > $SCRIPTPATH/utils/chuboe.properties.tmp
    mv $SCRIPTPATH/utils/chuboe.properties.tmp $SCRIPTPATH/utils/chuboe.properties
fi

#initialize variables with default values - these values might be overwritten during the next section based on command options
MY_IP=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
IS_INSTALL_DB="Y"
IS_MOVE_DB="N"
IS_INSTALL_ID="Y"
IS_LAUNCH_ID="N"
#IS_INSTALL_DESKTOP="N"
IS_INITIALIZE_DB=$CHUBOE_PROP_DB_IS_INITIALIZE
IS_SET_SERVICE_IP=$CHUBOE_PROP_IDEMPIERE_SET_SERVICE_IP
INSTALL_DATE=`date +%Y%m%d`_`date +%H%M%S`
ALTERNATE_PROP_FILE="NONE"
PIP=$CHUBOE_PROP_DB_HOST
DEVNAME="NONE"
DBPASS=$CHUBOE_PROP_DB_PASSWORD
DBPASS_SU=$CHUBOE_PROP_DB_PASSWORD_SU
INSTALLPATH=$CHUBOE_PROP_IDEMPIERE_PATH
TEMP_DIR="/tmp/chuboe-idempiere-install-files-$INSTALL_DATE/"
CHUBOE_UTIL=$CHUBOE_PROP_UTIL_PATH
CHUBOE_UTIL_HG=$CHUBOE_PROP_UTIL_HG_PATH
#ACTION - Next action to replace use of below properties individual with consolidated one.
CHUBOE_UTIL_HG_PROP_FILE="$CHUBOE_PROP_UTIL_HG_PROP_FILE"
README="$CHUBOE_UTIL/idempiere_installer_feedback.txt"
INITDNAME=$CHUBOE_PROP_IDEMPIERE_SERVICE_NAME
IDEMPIERE_VERSION=$CHUBOE_PROP_IDEMPIERE_VERSION
IDEMPIERE_DB_NAME=$CHUBOE_PROP_DB_NAME
IDEMPIERE_DB_USER=$CHUBOE_PROP_DB_USERNAME
IDEMPIERE_DB_USER_SU=$CHUBOE_PROP_DB_USERNAME_SU
JENKINSPROJECT=$CHUBOE_PROP_JENKINS_PROJECT
JENKINSURL=$CHUBOE_PROP_JENKINS_URL
JENKINS_CURRENT_REV=$CHUBOE_PROP_JENKINS_CURRENT_CHANGESET
ECLIPSE_SOURCE_HOSTPATH=$CHUBOE_PROP_ECLIPSE_SOURCE_HOSTPATH
ECLIPSE_SOURCE_FILENAME=$CHUBOE_PROP_ECLIPSE_SOURCE_FILENAME
OSUSER_EXISTS="N"
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
PGVERSION=$CHUBOE_PROP_DB_VERSION
PGPORT=$CHUBOE_PROP_DB_PORT
IS_REPLICATION="N"
REPLICATION_URL="Master"
IS_REPLICATION_MASTER="Y"
REPLATION_BACKUP_NAME="ID_Backup_$INSTALL_DATE"
REPLATION_ROLE="id_replicate_role"
REPLATION_TRIGGER="/tmp/id_pgsql.trigger.$PGPORT"
JENKINS_AUTHCOMMAND=$CHUBOE_PROP_JENKINS_AUTHCOMMAND

#create array of updated parameters to later update chuboe.properties
args=()
# }}}

# Read input flags
# {{{
# process the specified options
# the colon after the letter specifies there should be text with the option
# NOTE: include u because the script previously supported a -u OSUser
while getopts "$VARIABLE_FLAG_LIST" OPTION
do
    case $OPTION in
        h)  usage
            exit 1;;

        s)  #set the database to only run services on this machine
            IS_SET_SERVICE_IP="Y";;

        p)  #no install postgresql
            IS_INSTALL_DB="N"
            args+=("CHUBOE_PROP_DB_HOST=\"$OPTARG\"")
            PIP=$OPTARG;;

        e)  #move DB
            IS_MOVE_DB="Y"
            DEVNAME=$OPTARG;;

        i)  #no install iDempiere
            IS_INSTALL_ID="N";;

        P)  #database password
            args+=("CHUBOE_PROP_DB_PASSWORD=\"$OPTARG\"")
            args+=("CHUBOE_PROP_DB_PASSWORD_SU=\"$OPTARG\"")
            DBPASS=$OPTARG
            DBPASS_SU=$OPTARG;;

        l)  #launch iDempiere
            IS_LAUNCH_ID="Y";;

        D)  #install desktop development components
            echo " Develompment Environment installation moved to utils/chuboe_install_devenv.sh";;

        j)  #jenkins project
            args+=("CHUBOE_PROP_JENKINS_PROJECT=\"$OPTARG\"")
            JENKINSPROJECT=$OPTARG;;

        J)  #jenkins URL
            args+=("CHUBOE_PROP_JENKINS_URL=\"$OPTARG\"")
            JENKINSURL=$OPTARG;;

        b)  #jenkins build
            #Example: "5"
            #Example: "builds/5/"
            args+=("CHUBOE_PROP_JENKINS_BUILD_NUMBER=\"$OPTARG\"")
            CHUBOE_PROP_JENKINS_BUILD_NUMBER=$OPTARG;;

        v)  #idempiere version
            args+=("CHUBOE_PROP_IDEMPIERE_VERSION=\"$OPTARG\"")
            IDEMPIERE_VERSION=$OPTARG;;

        r)  #replication
            IS_REPLICATION="Y"
            REPLICATION_URL=$OPTARG;;

        I)  #do not initialize database
            IS_INITIALIZE_DB="N";;

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
# }}}

# Process variables after flags
# {{{
IDEMPIERESOURCE_HOSTPATH="$JENKINSURL/job/$JENKINSPROJECT/ws/${CHUBOE_PROP_JENKINS_BUILD_NUMBER}/org.idempiere.p2/target/products/org.adempiere.server.product/"
IDEMPIERESOURCE_FILENAME="idempiereServer"$IDEMPIERE_VERSION"Daily.gtk.linux.x86_64.zip"
IDEMPIERESOURCEPATHDETAIL="$JENKINSURL/job/$JENKINSPROJECT/ws/${CHUBOE_PROP_JENKINS_BUILD_NUMBER}/changes"

# get the current user and group
OSUSER=$(id -u -n)
OSUSER_GROUP=$(id -g -n)

# }}}

# Determine if IS_REPLICATION_MASTER should = N
# {{{
#  if not installing iDempiere and the user DID specify a URL to replicate from, then this instance is not a master.
echo "HERE: check if IS_REPLICATION_MASTER should = N"
if [[ $IS_INSTALL_ID == "N" && $REPLICATION_URL != "Master" ]]
then
    echo "HERE: Check if Is Replication Master"
    IS_REPLICATION_MASTER="N"
fi
# }}}

# Check if $OSUSER can create the temporary install folder
# {{{
echo "HERE: check if $OSUSER can create the temporary installation directory"
[ -d $TEMP_DIR ] || sudo mkdir $TEMP_DIR || { echo "HERE: failed to create $TEMP_DIR"; exit 1; }

sudo chmod -R go+w $TEMP_DIR
RESULT=$([ -d $TEMP_DIR ] && echo "Y" || echo "N")
# echo $RESULT
if [ $RESULT == "Y" ]; then
    echo "HERE: User can create temporary installation directory - placing temp installation details here $TEMP_DIR"
else
    echo "HERE: User cannot create the temporary installation directory"
    exit 1
fi
# }}}

# Check if iDempiere already exists
# {{{
RESULT=$([ -d $CHUBOE_PROP_IDEMPIERE_PATH ] && echo "Y" || echo "N")
# echo $RESULT
if [ $RESULT == "N" ]; then
    echo "HERE: iDempiere is not already installed - proceeding"
else
    echo "HERE: iDempiere is already installed - exiting now!"
    exit 1
fi
# }}}

# Check if you can create the chuboe folder
# {{{
# create a directory where chuboe related stuff will go. Including the helpful tips/hints/feedback file.
echo "HERE: check if you can create the $CHUBOE_UTIL directory"
[ -d $CHUBOE_UTIL ] || sudo mkdir $CHUBOE_UTIL || { echo "HERE: failed to create $CHUBOE_UTIL"; exit 1; }
sudo chown $OSUSER:$OSUSER_GROUP $CHUBOE_UTIL
sudo chmod -R go+w $CHUBOE_UTIL
RESULT=$([ -d $CHUBOE_UTIL ] && echo "Y" || echo "N")
# echo $RESULT
if [ $RESULT == "Y" ]; then
    echo "HERE: User can create chuboe directory - placing installation details here $CHUBOE_UTIL"
else
    echo "HERE: User cannot create the chuboe directory"
    exit 1
fi
# }}}

# Turn args array into a properties file and echo values.
# {{{
printf "%s\n" "${args[@]}" > $SCRIPTPATH/utils/install.properties
#Merge the newly create properties file back into chuboe.properties
awk -F= '!a[$1]++' $SCRIPTPATH/utils/install.properties $SCRIPTPATH/utils/chuboe.properties > $SCRIPTPATH/utils/chuboe.properties.tmp
mv $SCRIPTPATH/utils/chuboe.properties.tmp $SCRIPTPATH/utils/chuboe.properties
rm $SCRIPTPATH/utils/install.properties

# show variables to the user (debug)
echo "if you want to find for echoed values, search for HERE:"
echo "HERE: print variables"
echo "My IP="$MY_IP
echo "Install DB=" $IS_INSTALL_DB
echo "Move DB="$IS_MOVE_DB
echo "Install iDempiere="$IS_INSTALL_ID
echo "Initialize Database with iDempiere data="$IS_INITIALIZE_DB
echo "Set this machine as only server to run service="$IS_SET_SERVICE_IP
#echo "Install Desktop="$IS_INSTALL_DESKTOP
echo "Database IP="$PIP
echo "MoveDB Device Name="$DEVNAME
echo "DB Password="$DBPASS
echo "DB_SU Password="$DBPASS_SU
echo "Launch iDempiere with nohup="$IS_LAUNCH_ID
echo "Install Path="$INSTALLPATH
echo "Chuboe_Util Path="$CHUBOE_UTIL
echo "Chuboe_Properties file="$CHUBOE_UTIL_HG_PROP_FILE
echo "InitDName="$INITDNAME
echo "ScriptName="$SCRIPTNAME
echo "ScriptPath="$SCRIPTPATH
echo "Temp Directory="$TEMP_DIR
echo "OSUser="$OSUSER
echo "OSUser_Group="$OSUSER_GROUP
echo "iDempiere User="$IDEMPIEREUSER
echo "iDempiereSource_Hostpath="$IDEMPIERESOURCE_HOSTPATH
echo "iDempiereSource_Filename="$IDEMPIERESOURCE_FILENAME
echo "Eclipse_Source_Hostpath="$ECLIPSE_SOURCE_HOSTPATH
echo "Eclipse_Source_Filename="$ECLIPSE_SOURCE_FILENAME
echo "PG Version="$PGVERSION
echo "PG Port="$PGPORT
echo "Jenkins Project="$JENKINSPROJECT
echo "Jenkins URL="$JENKINSURL
echo "iDempiere Version"=$IDEMPIERE_VERSION
echo "Is Replication="$IS_REPLICATION
echo "Replication URL="$REPLICATION_URL
echo "Is Replication Master="$IS_REPLICATION_MASTER
echo "Replication Backup Name="$REPLATION_BACKUP_NAME
echo "Replication Role="$REPLATION_ROLE
echo "Replication Trigger="$REPLATION_TRIGGER
echo "HERE: Distro details:"
cat /etc/*-release
# }}}

# Create file to give user feedback about installation
# {{{
echo "Welcome to the iDempiere community.">$README
echo "The purpose of this file is to help you understand what this script accomplished.">>$README
echo "In the future, you can find this file in the $README directory.">>$README
echo "Press Ctrl+x to close this file and return to the prompt.">>$README
echo "If anything went wrong during the installation, you will see line in this file that begins with ERROR:">>$README
echo "If any part of this process is not clear, step-by-step instructions and video demonstrations are available in the site.">>$README
echo "---->http://erp-academy.chuckboecking.com">>$README
# }}}

# Check to ensure DB password is set
# {{{
if [[ $DBPASS == "NONE" && $IS_INSTALL_DB == "Y"  ]]
then
    echo "HERE: Must set DB Password if installing DB!!"
    echo "">>$README
    echo "">>$README
    echo "ERROR: Must set DB Password if installing DB!! Stopping script!">>$README
    exit 1
fi
# }}}

# Check if OS user exists
# {{{
RESULT=$(id -u $OSUSER)
if [ $RESULT -ge 0 ]; then
    echo "HERE: OSUser exists"
    echo "">>$README
    echo "">>$README
    echo "The specified OS user ($OSUSER) exists.">>$README
    echo "The script will use $OSUSER as the owner to the $CHUBOE_UTIL_HG directory.">>$README
    OSUSER_EXISTS="Y"
    OSUSER_HOME=$(eval echo ~$OSUSER)
else
    echo "ERROR: HERE: OSUser does not exist. Stopping script!"
    echo "">>$README
    echo "">>$README
    echo "ERROR: OSUser does not exist. Stopping script!">>$README
    exit 1
fi
# }}}

# Ubuntu prep
# {{{
# update the hosts file for ubuntu in AWS VPC - see the script for more details.
# If you are not running in AWS VPC, you can comment these lines out.
sudo chmod +x $SCRIPTPATH/utils/setHostName.sh
sudo $SCRIPTPATH/utils/setHostName.sh

# added needed repos
sudo apt --yes update
sudo apt --yes install gpg curl
# postgresql - example: used to install version 15 before officially supported on ubuntu 22.04

curl -fSsL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /usr/share/keyrings/postgresql.gpg > /dev/null
echo deb [arch=amd64,arm64,ppc64el signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main | sudo tee -a /etc/apt/sources.list.d/postgresql.list

# update apt package manager
sudo apt-get --yes update

# update locate database
sudo updatedb

# install useful utilities
sudo apt-get --yes install unzip htop expect bc telnet mercurial gpg curl
# }}}

# Download all files first
# {{{
# if [[ $IS_INSTALL_DESKTOP == "Y" ]] MOVED to external script
# then
    # $SCRIPTPATH/utils/downloadtestgz.sh $ECLIPSE_SOURCE_HOSTPATH $ECLIPSE_SOURCE_FILENAME $OSUSER_HOME/dev/downloads || exit 1
    #Note: if you already have a downloaded copy of iDempiere's hg repo zip, update the following URL
    # $SCRIPTPATH/utils/downloadtestzip.sh https://s3.amazonaws.com/ChuckBoecking/install/ idempiere-hg-download.zip $OSUSER_HOME/dev/ || exit 1
    # mv $OSUSER_HOME/dev/idempiere-hg-download.zip $OSUSER_HOME/dev/download.zip
    # if [ $? -ne 0 ]; then { echo "HERE: Can't rename $OSUSER_HOME/dev/idempiere-hg-download.zip" ; exit 1 ; } fi
# fi
if [[ $IS_INSTALL_ID == "Y" ]]
then
    $SCRIPTPATH/utils/downloadtestzip.sh $IDEMPIERESOURCE_HOSTPATH $IDEMPIERESOURCE_FILENAME $TEMP_DIR "$JENKINS_AUTHCOMMAND" || exit 1

    # preprocess the URL to ensure no double forward slash exists except for ://
    # remove double slashes = sed s#//*#/#g
    # add back :// = sed s#:/#://#g
    IDEMPIERESOURCEPATHDETAIL=$(echo $IDEMPIERESOURCEPATHDETAIL | sed 's|//*|/|g' | sed 's|:/|://|g')
    sudo wget $JENKINS_AUTHCOMMAND $IDEMPIERESOURCEPATHDETAIL -P $INSTALLPATH -O iDempiere_Build_Details_"$INSTALL_DATE".html
    if [ $? -ne 0 ]
    then
        echo "HERE: Failed to download $IDEMPIERESOURCEPATHDETAIL"
        #exit 1 - no need to exit just because it could not find the changes file.
    fi
fi
# }}}

# Virtualbox notes
# {{{
# if installing using virtualbox
# install the following before you install the guest additions
#   sudo apt-get install dkms gcc
# use the following instructions to prevent sudo timeout
# http://apple.stackexchange.com/questions/10139/how-do-i-increase-sudo-password-remember-timeout
# }}}

# Install desktop components MOVED TO EXTERNAL SCRIPT, NO LONGER INSTALLS DESKTOP
# {{{
#if [[ $IS_INSTALL_DESKTOP == "Y" ]]
#then
#    echo "HERE: Install desktop components because IS_INSTALL_DESKTOP == Y"
#    echo "">>$README
#    echo "">>$README
#    echo "Installing desktop components because IS_INSTALL_DESKTOP == Y">>$README
#
#    echo "HERE:Install maven"
#    sudo apt-get update
#    sudo apt-get install -y maven
#
#    echo "HERE:Installing desktop"
#    sudo apt-get update
#    sudo apt install -y --without-install-recommends ubuntu-gnome-desktop
#    sudo apt-get install -y chromium-browser gimp xarchiver gedit zip firefox
#
#    # install if you want to use pop theme
#    # sudo add-apt-repository ppa:system76/pop
#    # sudo apt update
#    # sudo apt install -y pop-gtk-theme pop-icon-theme gnome-tweak-tool
#
#    # remove sudo timeout
#    # sudo visudo
#    # add line: Defaults timestamp_timeout=-1
#
#    mkdir $OSUSER_HOME/dev
#    mkdir $OSUSER_HOME/dev/downloads
#    mkdir $OSUSER_HOME/dev/plugins
#
#    tar -zxvf $OSUSER_HOME/dev/downloads/$ECLIPSE_SOURCE_FILENAME -C $OSUSER_HOME/dev/
#
#    echo "">>$README
#    echo "">>$README
#    echo "NOTE: Creating an eclipse desktop shortcut.">>$README
#    echo "---> You probably want to set the -Xmx to 2g if you have enough memory - example: -Xmx2g">>$README
#
#    # Create shortcut with appropriate command arguments in base eclipse directory - copy this file to your Desktop when you login.
#    echo "[Desktop Entry]">$OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Encoding=UTF-8">> $OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Type=Application">> $OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Name=eclipse">> $OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Name[en_US]=eclipse">> $OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Icon=$OSUSER_HOME/dev/eclipse/icon.xpm">> $OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Exec=$OSUSER_HOME/dev/eclipse/eclipse  -vmargs -Xmx2g">> $OSUSER_HOME/dev/launchEclipse.desktop
#    echo "Comment[en_US]=">> $OSUSER_HOME/dev/launchEclipse.desktop
#
#    echo "">>$README
#    echo "">>$README
#    echo "A clean or pristine copy of the iDempiere code is downloaded to $OSUSER_HOME/dev/idempiere">>$README
#    echo "A working copy of iDempiere's code is downloaded to $OSUSER_HOME/dev/myexperiment">>$README
#    # get idempiere code
#    echo "HERE: Installing iDempiere via mercurial"
#    cd $OSUSER_HOME/dev
#
#    #Note: no longer perform the first clone - download the initial repo then clone.
#    #hg clone https://bitbucket.org/idempiere/idempiere
#
#    unzip idempiere-hg-download.zip
#    cd idempiere
#    hg pull $CHUBOE_PROP_JENKINS_REPO_URL
#
#    # create a copy of the idempiere code named myexperiment. Use the myexperiment repository and not the idempiere (pristine)
#    cd $OSUSER_HOME/dev
#    hg clone idempiere myexperiment
#    cd $OSUSER_HOME/dev/myexperiment
#    # create a targetPlatform directory for eclipse - used when materializing the project
#    mkdir $OSUSER_HOME/dev/myexperiment/targetPlatform
#    echo "HERE END: Installing iDempiere via mercurial"
#
#    echo "">>$README
#    echo "">>$README
#    echo "The working copy of iDempiere code in $OSUSER_HOME/dev/myexperiment has been updated to version $IDEMPIERE_VERSION">>$README
#    echo "The script downloaded binaries from the jenkins build: $JENKINSPROJECT">>$README
#    # this represents the current revision of the last jenkins.chuckboecking.com $IDEMPIERE_VERSION build
#    hg update -r $JENKINS_CURRENT_REV
#
#    # go back to home directory
#    cd
#
#    echo "">>$README
#    echo "">>$README
#    echo "This section discusses how to build iDempiere in Eclipse">>$README
#    echo "STEP 1">>$README
#    echo "To launch eclipse, copy the file named launchEclipse in the $OSUSER_HOME/dev/ folder to your desktop.">>$README
#    echo "Open Eclipse.">>$README
#    echo "Choose the myexperiment folder as your workspace when eclipse launches.">>$README
#    echo "Click on Help menu ==> Add New Software menu item ==> click the Add button.">>$README
#    echo "Add the mercurial and buckminster plugins.">>$README
#    echo " ---> Mercurial">>$README
#    echo " ------> https://bitbucket.org/mercurialeclipse/update-site/raw/default/">>$README
#    echo " ------> choose mercurial but not windows binaries">>$README
#    echo " ---> Buckminster">>$README
#    echo " ------> https://github.com/hengsin/bucky-updates-4.5/raw/master">>$README
#    echo " ------> choose Core, Maven, and PDE">>$README
#    echo " ---> JasperStudio (Optional for Jasper Reports)">>$README
#    echo " ------> http://jasperstudio.sf.net/updates">>$README
#    echo " ------> note: use Report Design perspective when ready to create reports.">>$README
#    echo "More detailed instructions for the following can be found at http://wiki.idempiere.org/en/Install_Development_Prerequisites">>$README
#    echo "">>$README
#    echo "">>$README
#    echo "STEP 2">>$README
#    echo "Click on Window > Preferences > Plug-in Development > Target Platform.">>$README
#    echo "Create your target platform.">>$README
#    echo "Click on File > Import > Buckminster > Materialize from Buckminster CQUERY.">>$README
#    echo "Materialize the project. If you browse to org.adempiere.sdk-feature/adempiere.cquery (instead of MSPEC),">>$README
#    echo " ---> eclipse will automatically build the workspace as part of the buckminster import process">>$README
#    echo "If you get errors when running install.app, try cleaning the project. Menu->Project->Clean">>$README
#    echo "If you are materializing the development or 3.0 branch, you might get errors with the org.zkoss.zk.library project.">>$README
#    echo " ---> If so, right-click on the org.zkoss.zk.library, and choose Buckminster->Envoke Action... -> fetch.dependency.jars and -> buckminster.clean actions.">>$README
#    echo "">>$README
#    echo "">>$README
#    echo "Important Note!">>$README
#    echo "iDempiere is installed twice: first as a service, and second in eclipse.">>$README
#    echo "If you run the iDempiere server through eclipse, make sure you stop the iDempiere service using 'sudo service idempiere stop' first.">>$README
#
#    echo "HERE END: Install desktop components because IS_INSTALL_DESKTOP == Y"
#
#fi #end if IS_INSTALL_DESKTOP = Y
# }}}

# Install database
# {{{
if [[ $IS_INSTALL_DB == "Y" ]]
then
    echo "HERE: Installing DB because IS_INSTALL_DB == Y"
    sudo apt-get --yes install apache2 postgresql-$PGVERSION postgresql-contrib-$PGVERSION libaprutil1-dbd-pgsql pgtop
    # note: some instances of ubuntu will not start postgresql automatically
    sudo service postgresql start
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '"$DBPASS_SU"';"
    sudo service postgresql stop

    # The following commands update postgresql to listen for all
    # connections (not just localhost). Make sure your firewall
    # prevents outsiders from connecting to your server.
    echo "">>$README
    echo "">>$README
    echo "PostgreSQL installed.">>$README
    echo "The script installed the phppgadmin tool to help you administer your database.">>$README
    echo "SECURITY NOTICE: Make sure your database is protected by a firewall that prevents direct connection from anonymous users.">>$README
    sudo sed -i '$ a\host   all     all     0.0.0.0/0       md5' /etc/postgresql/$PGVERSION/main/pg_hba.conf
    sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' /etc/postgresql/$PGVERSION/main/pg_hba.conf
    sudo sed -i '$ a\listen_addresses = '"'"'*'"'"' # chuboe '$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf

    # IS_Replication
    # {{{
    if [[ $IS_REPLICATION == "Y" ]]
    then
        echo "HERE: Is Replication = Y"
        # the following is true for both the master and the backup. PostgreSQL is smart enough to know to use the appropriate settings
        sudo sed -i "$ a\host    replication     $REPLATION_ROLE        0.0.0.0/0       md5" /etc/postgresql/$PGVERSION/main/pg_hba.conf
        echo "SECURITY NOTICE: Using a different Role for replication is a more safe option. It allows you to easily cut off replication in the case of a security breach.">>$README
        echo "SECURITY NOTICE: 0.0.0.0/0 should be changed to the subnet of the BACKUP servers to enhance security.">>$README
        sudo sed -i "$ a\wal_level = hot_standby # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
        sudo sed -i "$ a\archive_mode = on # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
        sudo sed -i "$ a\archive_command = 'cd .' # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
            # Note: the above commmand is needed so that the archive command returns successfully. Otherwise, you will get a log full of errors
        sudo sed -i "$ a\max_wal_senders = 5 # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
        #sudo sed -i "$ a\wal_keep_segments = 48 # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
	    # Note: wal_keep_segments was depricated in version 14
	sudo sed -i "$ a\wal_keep_size = 250 # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
	    # Note: size in MB according to 'select * from pg_settings where name = 'wal_keep_size''
        sudo sed -i "$ a\hot_standby = on # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf
        echo "NOTE: more detail about hot_standby logging overhead see: http://www.fuzzy.cz/en/articles/demonstrating-hot-standby-overhead/">>$README

        if [[ $REPLATION_ROLE != "postgres" ]]
        then
            sudo service postgresql start
            # remove replication attribute from postgres user/role for added security
            sudo -u postgres psql -c "alter role postgres with NOREPLICATION;"
            # create a new replication user. Doing so gives you the ability to cut off replication without disabling the postgres user.
            sudo -u postgres psql -c "CREATE ROLE $REPLATION_ROLE REPLICATION LOGIN PASSWORD '"$DBPASS_SU"';"
            sudo service postgresql stop
        fi

        echo "HERE END: Is Replication = Y"
    fi

    if [[ $IS_REPLICATION == "Y" && $IS_REPLICATION_MASTER == "N" ]]
    then
        echo "HERE: Is Replication = Y AND Is Replication Master = N"

        # create a .pgpass so that the replication does not need to ask for a password - you can also use key-based authentication
        sudo echo "$REPLICATION_URL:*:*:$REPLATION_ROLE:$DBPASS_SU">>/tmp/.pgpass
        sudo chown postgres:postgres /tmp/.pgpass
        sudo chmod 0600 /tmp/.pgpass
        sudo mv /tmp/.pgpass /var/lib/postgresql/

        # clear out the data directory for PostgreSQL - we will re-create it in the next section
        sudo rm -rf /var/lib/postgresql/$PGVERSION/main/
        sudo -u postgres mkdir /var/lib/postgresql/$PGVERSION/main
        sudo chmod 0700 /var/lib/postgresql/$PGVERSION/main

        # create a copy of the master and establish a recovery file (-R)
        sudo -u postgres pg_basebackup -X fetch -R -D /var/lib/postgresql/$PGVERSION/main -h $REPLICATION_URL -U $REPLATION_ROLE
        sudo sed -i "s|user=$REPLATION_ROLE|user=$REPLATION_ROLE application_name=$REPLATION_BACKUP_NAME|" /var/lib/postgresql/$PGVERSION/main/recovery.conf
        sudo sed -i "$ a\trigger_file = '$REPLATION_TRIGGER'" /var/lib/postgresql/$PGVERSION/main/recovery.conf

        echo "SECURITY NOTICE: This configuration does not use SSL for replication. If your database is not inside LAN and behind a firewall, enable SSL!">>$README
        echo "NOTE: Using the command 'touch /tmp/id_pgsql.trigger.$PGPORT' will promote the hot-standby server to a master.">>$README
        echo "NOTE: Verify that the MASTER sees the BACKUP as being replicated by issuing the following command from the MASTER:">>$README
        echo "--> sudo -u postgres psql -c 'select * from pg_stat_replication;'">>$README
        echo "NOTE: Verify that the BACKUP is receiving the stream by issuing the following command from the BACKUP:">>$README
        echo "--> ps -u postgres u">>$README
        echo "--> You should see something like: postgres: wal receiver process   streaming">>$README

        echo "HERE END: Is Replication = Y AND Is Replication Master = N"
    fi
    # }}}

    # Is_Install_ID
    # {{{
    if [[ $IS_INSTALL_ID == "N" ]]
    then
        #this is where we focus on database performance - when not installing tomcat/idempiere - just the database!

        #calculate memory
        TOTAL_MEMORY=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 / 1024)}')
        echo "total memory in MB="$TOTAL_MEMORY
        #assume that postgresql can use 85% of the system resources (pulled from chuboe.proprties)
        AVAIL_MEMORY=$(echo "$TOTAL_MEMORY*$CHUBOE_PROP_DB_OS_USAGE" | bc)
        AVAIL_MEMORY=${AVAIL_MEMORY%.*} # remove decimal
        echo "available memory in MB="$AVAIL_MEMORY

        #Key Concept: how to pipe content with sudo priviledge - the >> operator does not keep sudo priviledges
        #call on https://github.com/sebastianwebber/pgconfig-api webservice to get optimized pg parameters
        curl 'https://api.pgconfig.org/v1/tuning/get-config?environment_name=OLTP&format=conf&include_pgbadger=true&log_format=csvlog&max_connections=100&pg_version='$PGVERSION'&total_ram='$AVAIL_MEMORY'MB' >> $TEMP_DIR/pg.conf
	    if [ $? -eq 0 ]
	    then
		    cat $TEMP_DIR/pg.conf | sudo tee -a /etc/postgresql/$PGVERSION/main/postgresql.conf

		    echo "">>$README
		    echo "">>$README
		    echo "NOTE: this script uses https://www.pgconfig.org/#/tuning for postgresql tuning parameters">>$README
		    echo "NOTE: pgbadger is a good tool for analyzing postgresql logs">>$README
		    echo "--> See the chuboe_utils directory for installation directions">>$README
	    else
		    echo 'HERE ERROR: Failed to curl https://api.pgconfig.org/v1/tuning/get-config?environment_name=OLTP&format=conf&include_pgbadger=true&log_format=csvlog&max_connections=100&pg_version='$PGVERSION'&total_ram='$AVAIL_MEMORY'MB'
	    fi

        # sudo sed -i "$ a\random_page_cost = 2.0 # chuboe "$INSTALL_DATE /etc/postgresql/$PGVERSION/main/postgresql.conf

        # Be aware that pgtune has a reputation for being too generous with work_mem and shared_buffers.
        #   Setting these values too high can cause degraded performance.
        #   This is especially true if you perform high volumes of simple queries.
        # For more information about creating a highly available and fast database, consult:
        # --> http://www.amazon.com/PostgreSQL-9-High-Availability-Cookbook/dp/1849516960 -- chapter

        # Change 3 - kill the linux OOM    Killer. You hope your database takes up almost all the memory on your server.
        #    This section assumes that the database is the only application on this server.

        # Do this only after you vet and adjust the above settings. I am not convinced this step is the right thing to do.

        # Change 4 - Create cron job to FREEZE VACUUM as specific times - not when the DB thinks is the right time.
        # This step is handled manually.

    fi
    # }}}

    # start postgresql after all changes and before installing phppgadmin
    sudo service postgresql start

    # copy the phppgadmin apache2 configuration file that puts phppgadmin on port 8083
    sudo cp $SCRIPTPATH/web/000-phppgadmin.conf /etc/apache2/sites-enabled
    # remove the apache2 default site
    sudo unlink /etc/apache2/sites-enabled/000-default.conf
    # make apache listen on port 8083
    sudo sed -i '$ a\Listen 8083' /etc/apache2/ports.conf
    # remove phpphadmin's conf file - we will be using the above one instead
    sudo rm /etc/apache2/conf-enabled/phppgadmin.conf

    sudo service apache2 restart

    echo "">>$README
    echo "">>$README
    echo "SECURITY NOTICE: phppgadmin has been installed on port 8083.">>$README
    echo "Make sure this port is blocked from external traffic as a security measure.">>$README

    echo "HERE END: Installing DB because IS_INSTALL_DB == Y"

fi #end if IS_INSTALL_DB==Y
# }}}

# Move postgresql files to a separate device.
# {{{
# This is incredibly useful if you are running in AWS where if the server dies, you lose your work.
# By moving the DB files to an EBS drive, you help ensure your data will survive a server crash or shutdown.
# Make note that Ubuntu renames the device from s.. to xv.. For example, device sdh will get renamed to xvdh.
# The below code makes the mapping persist after a reboot by creating the fstab entry.
if [[ $IS_MOVE_DB == "Y" ]]
then
    echo "HERE: Moving DB because IS_MOVE_DB == Y"
    echo "">>$README
    echo "">>$README
    echo "The database files are being moved. You can access the mount directly at /vol">>$README
    sudo apt-get update
    sudo apt-get install -y xfsprogs
    #sudo apt-get install -y postgresql #uncomment if you need the script to install the db
    sudo mkfs.ext4 /dev/$DEVNAME
    echo "/dev/"$DEVNAME" /vol ext4 noatime 0 0" | sudo tee -a /etc/fstab
    sudo mkdir -m 000 /vol
    sudo mount /vol

    sudo service postgresql stop

    #map the data directory
    sudo mv /var/lib/postgresql/$PGVERSION/main /vol/var
    sudo chown -R postgres. /vol

    # updating postgresql.conf setting the new path
    sudo sed -i "s|data_directory.*|data_directory = '/vol/var'|" /etc/postgresql/$PGVERSION/main/postgresql.conf

    sudo service postgresql start

    echo "HERE END: Moving DB because IS_MOVE_DB == Y"

fi #end if IS_MOVE_DB==Y
# }}}

# Install iDempiere
# {{{
if [[ $IS_INSTALL_ID == "Y" ]]
then
    # create user documentation
    # {{{
    echo "HERE: Installing iDempiere because IS_INSTALL_ID == Y"
    echo "">>$README
    echo "">>$README
    echo "iDempiere is installed on this server">>$README
    echo "">>$README
    echo "">>$README
    echo "Note: The below command helps you prevent other users from seeing your home directory">>$README
    echo "--->sudo chmod -R o-rx $OSUSER_HOME">>$README

    echo "">>$README
    echo "">>$README
    echo "The script created an '$IDEMPIEREUSER' user without a password.">>$README
    echo "You can use the 'sudo -u $IDEMPIEREUSER LinuxCommandHere' process to execute tasks as that user.">>$README
    echo "You can use the 'sudo -i -u $IDEMPIEREUSER' to become the $IDEMPIEREUSER user.">>$README
    echo "Logging in as $IDEMPIEREUSER is often easier than issuing a bunch of sudo commands.">>$README
    echo "If you need to give $IDEMPIEREUSER a password, use the command 'sudo passwd $IDEMPIEREUSER'.">>$README
    # }}}

    # create IDEMPIEREUSER user and group
    # {{{
    # Note: we could create the iDempiere user as a system user; however, it is convenient to be able to "sudo -i -u $IDEMPIEREUSER" to perform tasks.
    sudo adduser $IDEMPIEREUSER --disabled-password --gecos "$IDEMPIEREUSER,none,none,none"
    # }}}

    # create database password file for iDempiere user
    # {{{
    sudo echo "*:*:*:$IDEMPIERE_DB_USER:$DBPASS">>$TEMP_DIR/.pgpass
    sudo echo "*:*:*:$IDEMPIERE_DB_USER_SU:$DBPASS_SU">>$TEMP_DIR/.pgpass
    sudo chown $IDEMPIEREUSER:$IDEMPIEREUSER $TEMP_DIR/.pgpass
    sudo -u $IDEMPIEREUSER chmod 600 $TEMP_DIR/.pgpass
    sudo mv $TEMP_DIR/.pgpass /home/$IDEMPIEREUSER/

    # create database password file for OSUSER user
    if [[ $OSUSER_EXISTS == "Y" ]]
    then
        sudo echo "*:*:*:$IDEMPIERE_DB_USER:$DBPASS">>$TEMP_DIR/.pgpass
        sudo echo "*:*:*:$IDEMPIERE_DB_USER_SU:$DBPASS_SU">>$TEMP_DIR/.pgpass
        sudo chown $OSUSER:$OSUSER_GROUP $TEMP_DIR/.pgpass
        sudo -u $OSUSER chmod 600 $TEMP_DIR/.pgpass
        sudo mv $TEMP_DIR/.pgpass $OSUSER_HOME/
    fi
    # }}}

    # install jdk and psql if $IS_INSTALL_DB == "N"
    # {{{
    sudo apt-get install $CHUBOE_PROP_JAVA_VERSION -y
    if [[ $IS_INSTALL_DB == "N" ]]
    then
        echo "HERE: install postgresql client tools"
        sudo apt-get -y install postgresql-client-$PGVERSION pgtop
    fi
    # }}}

    # make installpath and copy
    # {{{
    # clone id_installer again to chuboe_installpath

    sudo mkdir $INSTALLPATH
    sudo chown $IDEMPIEREUSER:$IDEMPIEREUSER $INSTALLPATH
    sudo chmod -R go+w $INSTALLPATH

    sudo unzip $TEMP_DIR/$IDEMPIERESOURCE_FILENAME -d $TEMP_DIR
    # FIXME: TODO: Change idempiere.gtk.linux.x86_64 directory name into an equate, i.e. split up extension and filename
    cd $TEMP_DIR/idempiere.gtk.linux.x86_64/idempiere-server/
    cp -r * $INSTALLPATH
    cd $INSTALLPATH
    # }}}

    # user documentation
    # {{{
    echo "">>$README
    echo "">>$README
    echo "This section applies to offsite backups.">>$README
    echo "The utilities directory includes some very useful scripts: $CHUBOE_UTIL_HG/utils">>$README
    echo "Issue the following commands to enable s3cmd and create an iDempiere backup bucket in S3.">>$README
    echo "---> s3cmd --configure">>$README
    echo "------> get your access key and secret key by logging into your AWS account">>$README
    echo "------> enter a password. Choose something different than your AWS password. Write it down!!">>$README
    echo "------> Accept the default path to GPG">>$README
    echo "------> Answer yes to HTTPS">>$README
    echo "Create your new S3 backup bucket">>$README
    echo "---> s3cmd mb s3://iDempiere_backup">>$README
    echo "IMPORTANT NOTE: the above S3 bucket name might not be available. If not, use something like iDempiere_backup_YOURNAME.">>$README
    echo "If you do need to change the bucket name, make sure both the backup and the restore scripts are updated accordingly.">>$README
    echo "">>$README
    echo "">>$README
    echo "To update your server's time zone, run this command:">>$README
    echo "---> sudo dpkg-reconfigure tzdata">>$README
    # }}}

    echo "HERE: Creating chuboe idempiere installation script directory"
    # {{{
    echo "">>$README
    echo "">>$README
    echo "The script is installing the ChuBoe idempiere installation script and utilties in $CHUBOE_UTIL_HG.">>$README
    echo "This utils directory has scripts that make supporting and maintaining iDempiere much much easier.">>$README
    cd $CHUBOE_UTIL
    mv $SCRIPTPATH .
    rm $CHUBOE_UTIL_HG/utils/chuboe.properties.orig
    # }}}

    #Only run import script if $IS_INITIALIZE_DB parameter set accordingly
    # {{{
    if [[ $IS_INITIALIZE_DB == "Y" ]]
    then
        echo "HERE: Initializing the database"
        cd $CHUBOE_UTIL_HG/utils
        # passing in root user to make the current user does not encounter permissions issues
        ./chuboe_idempiere_initdb.sh root
        echo "HERE END: Initializing the database"
    fi
    # }}}

    # add pgcrypto to support apache based authentication
    # {{{
    echo "HERE: pgcrypto extension"
    sudo -u $IDEMPIEREUSER psql -h $PIP -p $PGPORT -U $IDEMPIERE_DB_USER -d $IDEMPIERE_DB_NAME -c "CREATE EXTENSION pgcrypto"
    # }}}

    #update the database to only execute services on this machine
    # {{{
    if [[ $IS_SET_SERVICE_IP == "Y" ]]
    then
        sudo -u $IDEMPIEREUSER psql -h $PIP -p $PGPORT -U $IDEMPIERE_DB_USER -d $IDEMPIERE_DB_NAME -c "update ad_schedule set runonlyonip='$MY_IP'"
        sudo -u $IDEMPIEREUSER psql -h $PIP -p $PGPORT -U $IDEMPIERE_DB_USER -d $IDEMPIERE_DB_NAME -c "update AD_SysConfig set value='Q' where AD_SysConfig_ID=50034"
    fi
    # }}}

    echo "HERE: Launching console-setup.sh"
    # {{{
cd $INSTALLPATH

#FYI each line represents an input. Each blank line takes the console-setup.sh default.
#HERE are the prompts:
#jdk
#idempiere_home
#keystore_password - if run a second time, the lines beginning with dashes do not get asked again
#- common_name
#- org_unit
#- org
#- local/town
#- state
#- country
#host_name
#app_server_web_port
#app_server_ssl_port
#db_exists
#db_type
#db_server_host
#db_server_port
#db_name
#db_user
#db_password
#db_system_password
#mail_host
#mail_user
#mail_user_password
#mail_admin_email
#save_changes

#not indented because of file input
sh console-setup.sh <<!







CA
US



Y
2
$PIP
$PGPORT
$IDEMPIERE_DB_NAME
$IDEMPIERE_DB_USER
$DBPASS
$DBPASS_SU
mail.dummy.com



Y
!
#end of file input
echo "HERE END: Launching console-setup.sh"
# }}}


    # create mercurial hgrc file for project and create first commit.
    # {{{
    echo "[ui]">$CHUBOE_UTIL_HG/.hg/hgrc
    echo "username = YourName <YourName@YourURL.com>">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "[extensions]">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "purge =">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "hgext.mq =">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "extdiff =">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "[paths]">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "default = https://bitbucket.org/cboecking/idempiere-installation-script">>$CHUBOE_UTIL_HG/.hg/hgrc
    echo "default-push = /dev/null/">>$CHUBOE_UTIL_HG/.hg/hgrc

    cd $CHUBOE_UTIL_HG
    hg commit -m "commit after installation - updated variables specific to this installation"
    # }}}

    #prevent the backup's annoying 30 second delay
    sed -i "s|sleep 30|#sleep 30|" "$INSTALLPATH/utils/myDBcopy.sh"

    # if server is dedicated to iDempiere, give it more java power
    # {{{
    TOTAL_MEMORY=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 / 1024)}')
    echo "total memory in MB="$TOTAL_MEMORY
    AVAIL_MEMORY=$(echo "$TOTAL_MEMORY*$CHUBOE_PROP_IDEMPIERE_OS_USAGE" | bc)
    AVAIL_MEMORY=${AVAIL_MEMORY%.*} # remove decimal
    echo "available memory in MB="$AVAIL_MEMORY
    if [[ $AVAIL_MEMORY -gt 1000 && $IS_INSTALL_DB == "N" ]]
    then
        echo "HERE: lots of memory and dedicated idempiere server"
        XMX=1024
        if [[ $AVAIL_MEMORY -gt 2048 ]]
            then XMX=2048
        fi
        if [[ $AVAIL_MEMORY -gt 4096 ]]
            then XMX=4096
        fi
        if [[ $AVAIL_MEMORY -gt 8192 ]]
            then XMX=8192
        fi
        if [[ $AVAIL_MEMORY -gt 16384 ]]
            then XMX=16384
        fi
        if [[ $AVAIL_MEMORY -gt 32768 ]]
            then XMX=32768
        fi
        echo "XMX="$XMX
        #sudo sed -i "s|IDEMPIERE_JAVA_OPTIONS=.*|IDEMPIERE_JAVA_OPTIONS=\"-Xmx"$XMX"m -Xms"$XMX"m -DIDEMPIERE_HOME=\$IDEMPIERE_HOME\"|g" $INSTALLPATH/utils/myEnvironment.sh
	sudo sed -i "s|\bXmx\S*|Xmx"$XMX"m|g" $INSTALLPATH/utils/myEnvironment.sh
	sudo sed -i "s|\bXms\S*|Xms"$XMX"m|g" $INSTALLPATH/utils/myEnvironment.sh
        # use the following command to confirm the above setting took: sudo -u $IDEMPIEREUSER jps -v localhost
        echo "HERE END: lots of memory and dedicated idempiere server"
    fi
    # }}}

    #update ownership and write privileges after installation is complete
    # {{{
    sudo chown -R $IDEMPIEREUSER:$IDEMPIEREUSER $INSTALLPATH
    sudo chown -R $OSUSER:$OSUSER_GROUP $CHUBOE_UTIL
    sudo chmod -R go-w $INSTALLPATH
    sudo chmod -R go-w $CHUBOE_UTIL
    sudo chmod u+x $CHUBOE_UTIL_HG/*.sh
    sudo chmod u+x $CHUBOE_UTIL_HG/utils/*.sh
    sudo chmod 600 $INSTALLPATH/idempiereEnv.properties
    sudo chmod 600 $CHUBOE_UTIL_HG/utils/chuboe.properties
    # }}}

    # add OSUSER to IDEMPIEREUSER group
    # {{{
    if [[ $IDEMPIEREUSER != $OSUSER ]]
    then
        echo "HERE: adding $OSUSER to $IDEMPIEREUSER group"
        sudo usermod -a -G $IDEMPIEREUSER $OSUSER
        echo "">>$README
        echo "">>$README
        echo "Your user ($OSUSER) has been added to the $IDEMPIEREUSER group.">>$README
        echo "You must restart your current SSH session for this setting to take effect.">>$README
    fi
    # }}}

    echo "HERE: configure apache to present webui on port 80 - reverse proxy"
    # {{{
    # install apache2 if missed during db/phpgadmin
    if [[ $IS_INSTALL_DB == "N" ]]
    then
        sudo apt-get install -y apache2
    fi

    # copy the iDempiere apache2 configuration file
    sudo cp "$CHUBOE_UTIL_HG/web/$CHUBOE_PROP_IDEMPIERE_APACHE_CONFIG" /etc/apache2/sites-enabled

    #create self-signed certificates if needed
    echo "HERE: create self-signed cert if needed"
    if [[ $CHUBOE_PROP_IDEMPIERE_APACHE_SELFSIGN == "Y" ]]
    then
        "$CHUBOE_UTIL_HG/utils/chuboe_selfsign_cert.sh"
    fi

    # remove the apache2 default site
    sudo unlink /etc/apache2/sites-enabled/000-default.conf

    # apache modules needed to support reverse proxy
    sudo a2enmod proxy
    sudo a2enmod proxy_http
    sudo a2enmod proxy_ajp
    sudo a2enmod rewrite
    sudo a2enmod deflate
    sudo a2enmod headers
    sudo a2enmod proxy_balancer
    sudo a2enmod proxy_connect
    sudo a2enmod proxy_html
    sudo a2enmod dbd
    sudo a2enmod authn_dbd
    sudo a2enmod ssl
    sudo service apache2 restart
    # }}}

    #Take a back up of the iDempiere binary installation directory
    # {{{
    echo "HERE: create a backup of the iDempiere binaries"
    cd $CHUBOE_UTIL_HG/utils
    ./chuboe_hg_bindir.sh
    echo "HERE END: create a backup of the iDempiere binaries"
    # }}}

    #Execute an update to get the latest version of the code and database
    # {{{
    if [[ $IS_INITIALIZE_DB == "Y" ]]
    then
        echo "HERE: updating database to latest version"
        cd $CHUBOE_UTIL_HG/utils
        ./chuboe_idempiere_upgrade.sh -s -p
        echo "HERE END: updating database and binaries to latest version"
    fi
    # }}}

    echo "HERE END: Installing iDempiere because IS_INSTALL_ID == Y"

fi #end if $IS_INSTALL_ID == "Y"
# }}}

# Run iDempiere
# {{{
if [[ $IS_LAUNCH_ID == "Y" ]]
then
    echo "HERE: IS_LAUNCH_ID == Y"
    echo "HERE: setting iDempiere to start on boot"
    echo "">>$README
    echo "">>$README
    echo "iDempiere is started and is set to start on system boot">>$README
    sudo -u $IDEMPIEREUSER cp $CHUBOE_UTIL_HG/stopServer.sh $INSTALLPATH/utils
    sudo cp $CHUBOE_UTIL_HG/$INITDNAME /etc/init.d/
    sudo chmod +x /etc/init.d/$INITDNAME
    # remove dependency on postgres if not installed on this machine
    if [[ $IS_INSTALL_DB == "N" ]]
    then
        sudo sed -i "s|# Required-Start:	postgresql|# Required-Start:|" /etc/init.d/$INITDNAME
        sudo sed -i "s|# Required-Stop:	postgresql|# Required-Stop:|" /etc/init.d/$INITDNAME
    fi
    sudo update-rc.d $INITDNAME defaults
    sudo /etc/init.d/$INITDNAME start
    echo "HERE END: IS_LAUNCH_ID == Y"
fi
# }}}

# Cleanup and exit
# {{{
echo "">>$README
echo "">>$README
echo "Congratulations - the script seems to have executed successfully.">>$README

#clean up activities
sudo chmod -R go-w $TEMP_DIR

#remove passwords from chuboe.properties file.
#the password can be retrieved from the idempiere properties file if needed.
#sed -i "/CHUBOE_PROP_DB_PASSWORD/d" $CHUBOE_UTIL_HG_PROP_FILE

exit 0
# }}}

# Utity scripts
# {{{
#the following is not currently used; however, keeping for reference.
#update a proert file with a new value.
set_chuboe_property (){
SET_PROP_TARGET_PROPERTY=$1
SET_PROP_REPLACEMENT_VALUE=$2
sed -i "s/\($SET_PROP_TARGET_PROPERTY *= *\).*/\1$SET_PROP_REPLACEMENT_VALUE/" $CHUBOE_UTIL_HG_PROP_FILE
}
# }}}

