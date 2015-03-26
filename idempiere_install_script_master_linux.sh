#!/bin/bash

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

# function to help the user better understand how the script works
usage()
{
cat << EOF

usage: $0

This script helps you launch the appropriate
iDempiere components on a given server

OPTIONS:
	-h	Help
	-s	Prevent this server from running
		services like accounting and workflow
		(not implemented yet)
	-p 	No install postgresql - provide the
		IP for the postgresql server
	-e	Move the postgresql files
		to EBS - provide the drive name
	-i	No install iDempiere (DB only)
	-P	DB password
	-l	Launch iDempiere as service
	-u	Adds this user to the iDempiere group (default: ubuntu)
	-B	Use bleeding edge copy of iDempiere (defaults to 2.1)
	-D	Install desktop development tools
	-j	Specify specific Jenkins build
	-r	Add Hot_Standby Replication - a parameter of "Master" indicates the db will be a Master. A parameter for a URL should point to a master and therefore will make this db a Backup

Outstanding actions:
* Add a -t flag to allow for giving a server a specific name
	 - update the $PS1 command prompt with new name
	 - append the tag to the end of the database name: i.e. -t dev-01 would create idempiere-dev-01
	 - test all scripts to make sure they work with the different datbase name
* Create flag or convention to change username and passwords for system generated entries (i.e. MaxSuperUser and MaxSystem)
	 - add this information to the idempiere feedback file
* Review the output formatting of the idempiere feedback file - make sure it is consistent and looks good.
* Create option to specify password during installation - as opposed to as a command line option
* Create SQL script with Chucks Favorite changes:
	- set files to be stored at the file system (not os) - see below drive for attachments
	- Set Account Default field names to the more logical names like: "AP For Invoices, AP for Payments, Not Received Invoices, etc..)
* Update script to make better use of HOME_DIR variable when writing to files i.e. feedback file.
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


EOF
}

#initialize variables with default values - these values might be overwritten during the next section based on command options
IS_INSTALL_DB="Y"
IS_INSTALL_SERVICE="Y"
IS_MOVE_DB="N"
IS_INSTALL_ID="Y"
IS_LAUNCH_ID="N"
IS_INSTALL_DESKTOP="N"
IS_BLEED_EDGE="N"
PIP="localhost"
DEVNAME="NONE"
DBPASS="NONE"
HOME_DIR="/tmp/chuboe-idempiere-server/"
README="$HOME_DIR/idempiere_installer_feedback.txt"
INSTALLPATH="/opt/idempiere-server/"
CHUBOE_UTIL="/opt/chuboe_utils/"
CHUBOE_UTIL_HG="$CHUBOE_UTIL/idempiere-installation-script/"
CHUBOE_UTIL_HG_PROP="$CHUBOE_UTIL_HG/utils/properties/"
INITDNAME="idempiere"
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
IDEMPIERE_VERSION="2.1"
JENKINSPROJECT="iDempiere"$IDEMPIERE_VERSION"Daily"
ECLIPSESOURCEPATH="http://download.springsource.com/release/ECLIPSE/kepler/SR1/eclipse-jee-kepler-SR1-linux-gtk-x86_64.tar.gz"
OSUSER="ubuntu"
IDEMPIEREUSER="idempiere"
PGVERSION="9.3"
IS_REPLICATION="N"
REPLICATION_URL="Master"
IS_REPLICATION_MASTER="Y"
REPLATION_BACKUP_NAME="ID_Backup_"`date +%Y%m%d`_`date +%H%M%S`
REPLATION_ROLE="id_replicate_role"
REPLATION_TRIGGER="/tmp/id_pgsql.trigger.5432"

# process the specified options
# the colon after the letter specifies there should be text with the option
while getopts "hsp:e:ib:P:lu:BDj:r:" OPTION
do
	case $OPTION in
		h)	usage
			exit 1;;

		s)	#no install services like accounting and workflow
			IS_INSTALL_SERVICE="N"
			echo "NOTE: -s option Not implemented yet!!";;

		p)	#no install postgresql
			IS_INSTALL_DB="N"
			PIP=$OPTARG;;

		e)	#move DB
			IS_MOVE_DB="Y"
			DEVNAME=$OPTARG;;

		i)	#no install iDempiere
			IS_INSTALL_ID="N";;

		P)	#database password
			DBPASS=$OPTARG;;

		l)	#launch iDempiere
			IS_LAUNCH_ID="Y";;

		u)	#user
			OSUSER=$OPTARG;;

		B)	#use bleeding edge copy of iDempiere
			IS_BLEED_EDGE="Y";;

		D)	#install desktop development components
			IS_INSTALL_DESKTOP="Y";;

		j)	#jenkins project
			IS_BLEED_EDGE="Y"
			JENKINSPROJECT=$OPTARG;;

		r)	#replication
			IS_REPLICATION="Y"
			REPLICATION_URL=$OPTARG;;

	esac
done

IDEMPIERECLIENTPATH="http://superb-dca2.dl.sourceforge.net/project/idempiere/v"$IDEMPIERE_VERSION"/swing-client/idempiereClient.gtk.linux.x86_64.zip"
IDEMPIERECLIENTPATHBLEED="http://jenkins.idempiere.com/job/$JENKINSPROJECT/ws/buckminster.output/org.adempiere.ui.swing_"$IDEMPIERE_VERSION".0-eclipse.feature/idempiereClient.gtk.linux.x86_64.zip"
IDEMPIERESOURCEPATH="http://superb-dca2.dl.sourceforge.net/project/idempiere/v"$IDEMPIERE_VERSION"/server/idempiereServer.gtk.linux.x86_64.zip"
IDEMPIERESOURCEPATHBLEED="http://jenkins.idempiere.com/job/$JENKINSPROJECT/ws/buckminster.output/org.adempiere.server_"$IDEMPIERE_VERSION".0-eclipse.feature/idempiereServer.gtk.linux.x86_64.zip"
IDEMPIERESOURCEPATHBLEEDDETAIL="http://jenkins.idempiere.com/job/$JENKINSPROJECT/changes"

#if bleeding edge
echo "HERE: check if is Bleeding edge"
if [[ $IS_BLEED_EDGE == "Y" ]]
then
	echo "HERE: update source and client paths"
	IDEMPIERESOURCEPATH=$IDEMPIERESOURCEPATHBLEED
	IDEMPIERECLIENTPATH=$IDEMPIERECLIENTPATHBLEED
fi

#determine if IS_REPLICATION_MASTER should = N
#  if not installing iDempiere and the user DID specify a URL to replicate from, then this instance is not a master.
echo "HERE: check if IS_REPLICATION_MASTER should = N"
if [[ $IS_INSTALL_ID == "N" && $REPLICATION_URL != "Master" ]]
then
	echo "HERE: Check if Is Replication Master"
	IS_REPLICATION_MASTER="N"
fi

# Check if you can create a temp folder
echo "HERE: check if you can create a temp folder"
sudo mkdir $HOME_DIR
sudo chmod 0777 $HOME_DIR
RESULT=$([ -d $HOME_DIR ] && echo "Y" || echo "N")
# echo $RESULT
if [ $RESULT == "Y" ]; then
	echo "HERE: User can create a temp directory - placing installation details here $HOME_DIR"
else
	echo "HERE: User cannot create a temp directory"
	exit 1
fi

# show variables to the user (debug)
echo "if you want to find for echoed values, search for HERE:"
echo "HERE: print variables"
echo "Install DB=" $IS_INSTALL_DB
echo "Move DB="$IS_MOVE_DB
echo "Install iDempiere="$IS_INSTALL_ID
echo "Install iDempiere Services="$IS_INSTALL_SERVICE
echo "Install Desktop="$IS_INSTALL_DESKTOP
echo "Database IP="$PIP
echo "MoveDB Device Name="$DEVNAME
echo "DB Password="$DBPASS
echo "Launch iDempiere with nohup="$IS_LAUNCH_ID
echo "Install Path="$INSTALLPATH
echo "Chuboe_Util Path="$CHUBOE_UTIL
echo "Chuboe_Properties Path="$CHUBOE_UTIL_HG_PROP
echo "InitDName="$INITDNAME
echo "ScriptName="$SCRIPTNAME
echo "ScriptPath="$SCRIPTPATH
echo "Home Directory="$HOME_DIR
echo "OSUser="$OSUSER
echo "iDempiere User="$IDEMPIEREUSER
echo "Use bleeding edge="$IS_BLEED_EDGE
echo "iDempiereSourcePath="$IDEMPIERESOURCEPATH
echo "iDempiereClientPath="$IDEMPIERECLIENTPATH
echo "EclipseSourcePath="$ECLIPSESOURCEPATH
echo "PG Version="$PGVERSION
echo "Jenkins Project="$JENKINSPROJECT
echo "Is Replication="$IS_REPLICATION
echo "Replication URL="$REPLICATION_URL
echo "Is Replication Master="$IS_REPLICATION_MASTER
echo "Replication Backup Name="$REPLATION_BACKUP_NAME
echo "Replication Role="$REPLATION_ROLE
echo "Replication Trigger="$REPLATION_TRIGGER
echo "Distro details:"
cat /etc/*-release

# Create file to give user feedback about installation
echo "">$README
echo "Welcome to the iDempiere Installer.">$README
echo "The purpose of this file is to help you understand what this script accomplished.">$README
echo "If anything went wrong during the installation, you will see line in this file that begins with ERROR:">$README
echo "If any part of this process is not clear, step-by-step instructions and video demonstrations are available in the erp-academy.chuckboecking.com site.">$README

# Check to ensure DB password is set
if [[ $DBPASS == "NONE" && $IS_INSTALL_DB == "Y"  ]]
then
	echo "HERE: Must set DB Password if installing DB!!"
	echo "">$README
	echo "">$README
	echo "ERROR: Must set DB Password if installing DB!! Stopping script!">>$README
	exit 1
fi

# update the hosts file for ubuntu in AWS VPC - see the script for more details.
# If you are not running in AWS VPC, you can comment these lines out.
sudo chmod +x $SCRIPTPATH/utils/setHostName.sh
sudo $SCRIPTPATH/utils/setHostName.sh

# update apt package manager
sudo apt-get --yes update

# update locate database
sudo updatedb

# install useful utilities
sudo apt-get --yes install unzip htop s3cmd expect

# install database
if [[ $IS_INSTALL_DB == "Y" ]]
then
	echo "HERE: Installing DB because IS_INSTALL_DB == Y"
	echo "Installing DB because IS_INSTALL_DB == Y">>$README
	sudo apt-get --yes install postgresql postgresql-contrib phppgadmin libaprutil1-dbd-pgsql
	sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '"$DBPASS"';"
	sudo -u postgres service postgresql stop

	# The following commands update postgresql to listen for all
	# connections (not just localhost). Make sure your firewall
	# prevents outsiders for connecting to your server.
	echo "SECURITY NOTICE: Make sure your database is protected by a firewall that prevents direct connection from anonymous users">>$README
	sudo sed -i '$ a\host   all     all     0.0.0.0/0       md5' /etc/postgresql/$PGVERSION/main/pg_hba.conf
	sudo sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' /etc/postgresql/$PGVERSION/main/pg_hba.conf
	sudo sed -i '$ a\listen_addresses = '"'"'*'"'"' # chuboe '`date +%Y%m%d` /etc/postgresql/$PGVERSION/main/postgresql.conf

	if [[ $IS_REPLICATION == "Y" ]]
	then
		echo "HERE: Is Replication = Y"
		# the following is true for both the master and the backup. PostgreSQL is smart enough to know to use the appropriate settings
		sudo sed -i "$ a\host    replication     $REPLATION_ROLE        0.0.0.0/0       md5" /etc/postgresql/$PGVERSION/main/pg_hba.conf
		echo "SECURITY NOTICE: Using a different Role for replication is a more safe option. It allows you to easily cut of replication in the case of a security breach.">>$README
		echo "SECURITY NOTICE: 0.0.0.0/0 should be changed to the subnet of the BACKUP servers to enhance security.">>$README
		sudo sed -i "$ a\wal_level = hot_standby # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\archive_mode = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\archive_command = 'cd .' # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
			# Note: the above commmand is needed so that the archive command returns successfully. Otherwise, you will get a log full of errors
		sudo sed -i "$ a\max_wal_senders = 5 # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\wal_keep_segments = 48 # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\hot_standby = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		echo "NOTE: more detail about hot_standby logging overhead see: http://www.fuzzy.cz/en/articles/demonstrating-hot-standby-overhead/">>$README

		if [[ $REPLATION_ROLE != "postgres" ]]
		then
			sudo -u postgres service postgresql start
			# remove replication attribute from postgres user/role for added security
			sudo -u postgres psql -c "alter role postgres with NOREPLICATION;"
			# create a new replication user. Doing so gives you the ability to cut-off replication without disabling the postgres user.
			sudo -u postgres psql -c "CREATE ROLE $REPLATION_ROLE REPLICATION LOGIN PASSWORD '"$DBPASS"';"
			sudo -u postgres service postgresql stop
		fi

		echo "HERE END: Is Replication = Y"
	fi

	if [[ $IS_REPLICATION == "Y" && $IS_REPLICATION_MASTER == "N" ]]
	then
		echo "HERE: Is Replication = Y AND Is Replication Master = N"

		# create a .pgpass so that the replication does not need to ask for a password - you can also use key-based authentication
		sudo echo "$REPLICATION_URL:*:*:$REPLATION_ROLE:$DBPASS">>/tmp/.pgpass
		sudo chown postgres:postgres /tmp/.pgpass
		sudo chmod 0600 /tmp/.pgpass
		sudo mv /tmp/.pgpass /var/lib/postgresql/

		# clear out the data directory for PostgreSQL - we will re-create it in the next section
		sudo rm -rf /var/lib/postgresql/$PGVERSION/main/
		sudo -u postgres mkdir /var/lib/postgresql/$PGVERSION/main
		sudo chmod 0700 /var/lib/postgresql/$PGVERSION/main

		# create a copy of the master and establish a recovery file (-R)
		sudo -u postgres pg_basebackup -x -R -D /var/lib/postgresql/$PGVERSION/main -h $REPLICATION_URL -U $REPLATION_ROLE
		sudo sed -i "s|user=$REPLATION_ROLE|user=$REPLATION_ROLE application_name=$REPLATION_BACKUP_NAME|" /var/lib/postgresql/$PGVERSION/main/recovery.conf
		sudo sed -i "$ a\trigger_file = '$REPLATION_TRIGGER'" /var/lib/postgresql/$PGVERSION/main/recovery.conf

		echo "SECURITY NOTICE: This configuration does not use SSL for replication. If you database is not inside LAN and behind a firewall, enable SSL!">>$README
		echo "NOTE: Using the command 'touch /tmp/id_pgsql.trigger.5432' will promote the hot-standby server to a master.">>$README
		echo "NOTE: Verify that the MASTER sees the BACKUP as being replicated by issuing the following command from the MASTER:">>$README
		echo "--> sudo -u postgres psql -c 'select * from pg_stat_replication;'">>$README
		echo "NOTE: Verify that the BACKUP is receiving the stream by issuing the following command from the BACKUP:">>$README
		echo "--> ps -u postgres u">>$README
		echo "--> You should see something like: postgres: wal receiver process   streaming">>$README

		echo "HERE END: Is Replication = Y AND Is Replication Master = N"
	fi

	if [[ $IS_INSTALL_ID == "N" ]]
	then
		#this is where we focus on database performance - when not installing tomcat/idempiere - just the database!

		# Change 1 - turn on logging - requires little overhead and provide much information 
		#	Remember most performance issues are application related - not necessarily database parameters
		#   Logging gives you great insight into how the application is running.
		sudo sed -i "$ a\log_destination = 'csvlog' # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\logging_collector = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_rotation_size = 1GB # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_connections = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_disconnections = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_lock_waits = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_temp_files = 0 # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_min_duration_statement = 1000 # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\log_checkpoints = on # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf

		# Change 2 - postgresql.comf related changes
		# TOTAL_MEMORY=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 / 1024)}')
		sudo apt-get install -y pgtune
		sudo -u postgres mv /etc/postgresql/$PGVERSION/main/postgresql.conf{,.orig}
		sudo -u postgres pgtune -i /etc/postgresql/$PGVERSION/main/postgresql.conf.orig -o /etc/postgresql/$PGVERSION/main/postgresql.conf
		sudo sed -i "$ a\random_page_cost = 2.0 # chuboe `date +%Y%m%d`" /etc/postgresql/$PGVERSION/main/postgresql.conf
		# Be aware that pgtune has a reputation for being too generous with work_mem and shared_buffers. 
		#   Setting these values too high can cause degraded performance.
		#	This is especially true if you perform high volumes of simple queries.
		# For more information about creating a highly available and fast database, consult:
		# --> http://www.amazon.com/PostgreSQL-9-High-Availability-Cookbook/dp/1849516960 -- chapter 

		# Change 3 - kill the linux OOM	Killer. You hope your database takes up almost all the memory on your server. 
		#	This section assumes that the database is the only application on this server.

		# Do this only after you vet and adjust the above settings. I am not convinced this step is the right thing to do.

		# Change 4 - Create cron job to FREEZE VACUUM as specific times - not when the DB thinks is the right time.
		# This step is handled manually.

	fi

	# start postgresql after all changes and before installing phppgadmin
	sudo -u postgres service postgresql start

	# copy the phppgadmin apache2 configuration file that puts phppgadmin on port 8083
	sudo cp $SCRIPTPATH/web/000-phppgadmin.conf /etc/apache2/sites-enabled
	# remove the apache2 default site
	sudo unlink /etc/apache2/sites-enabled/000-default.conf
	# make apache listenon port 8083
	sudo sed -i '$ a\Listen 8083' /etc/apache2/ports.conf

	sudo service apache2 restart

	echo "">>$README
	echo "">>$README
	echo "SECURITY NOTICE: phppgadmin has been installed on port 8083.">>$README
	echo "Make sure this port is blocked from external traffic as a security mesaure.">>$README

	echo "HERE END: Installing DB because IS_INSTALL_DB == Y"

fi #end if IS_INSTALL_DB==Y

# install desktop components
if [[ $IS_INSTALL_DESKTOP == "Y" ]]
then
	echo "HERE: Install desktop components because IS_INSTALL_DESKTOP == Y"
	echo "">>$README
	echo "">>$README
	echo "Installing desktop components because IS_INSTALL_DESKTOP == Y">>$README

	# Check if OS user exists
	RESULT=$(id -u $OSUSER)
	if [ $RESULT -ge 0 ]; then
		echo "HERE: OSUser exists"
	else
		echo "ERROR: HERE: OSUser does not exist. Stopping script!"
		echo "">$README
		echo "">$README
		echo "ERROR: OSUser does not exist. OSUser is needed when installing the development environment. Stopping script!">>$README
		# nano /home/$OSUSER/$README
		exit 1
	fi

	# nice MATE desktop installation (compatible with 14.04)
	# http://wiki.mate-desktop.org/download)
	echo "HERE:Installing xrdp and ubuntu-mate-desktop"
	sudo apt-get install -y xrdp
	sudo apt-add-repository -y ppa:ubuntu-mate-dev/ppa
	sudo apt-add-repository -y ppa:ubuntu-mate-dev/trusty-mate
	sudo apt-get update
	# the below line will install a smaller footprint desktop. Comment out the ubuntu-mate-core ubuntu-mate-desktop line if you use it.
	# sudo apt-get install -y mate-desktop-environment
	sudo apt-get install -y ubuntu-mate-core ubuntu-mate-desktop
	sudo apt-get install -y chromium-browser gimp xarchiver
	echo mate-session> ~/.xsession
	sudo sed -i "s|port=-1|port=ask-1|" /etc/xrdp/xrdp.ini
	sudo service xrdp restart

	#new desktop installation (compatible with 14.04) - alternative to Mate Desktop
	#sudo apt-get install -y xrdp lxde
	#sudo apt-get install -y chromium-browser leafpad xarchiver gimp
	#echo lxsession -s LXDE -e LXDE >/home/$OSUSER/.xsession
	#sudo sed -i "s|port=-1|port=ask-1|" /etc/xrdp/xrdp.ini
	#sudo service xrdp restart

	echo "HERE: set the ubuntu password using passwd command to log in remotely"
	echo "">>$README
	echo "">>$README
	echo "ACTION REQUIRED: before you can log in using remote desktop, you must set the ubuntu password using 'passwd' command.">>$README
	echo "---> to set the password for the ubuntu user: 'sudo passwd $OSUSER'">>$README
	echo "---> the script installed 'xrdp' with allows you to use Windows Remote Desktop to connect.">>$README
	echo "">>$README
	echo "">>$README
	echo "NOTE: Use the following linux command to see what XRDP/VNC sessions are open:">>$README
	echo "---> wvnc -> which is short for: sudo netstat -tulpn | grep Xvnc">>$README
	echo "---> It is usually 5910 the first time you connect.">>$README
	echo "NOTE: Desktop niceties - right-click on dekstop -> change desktop background:">>$README
	echo "---> set desktop wallpaper to top-left gradient">>$README
	echo "---> set theme to menta">>$README
	echo "---> set fixed width font to monospace">>$README
	echo "NOTE: Command/Terminal niceties - edit -> Profile Preferences:">>$README
	echo "---> General Tab -> turn off the terminal bell">>$README
	echo "---> Colors tab -> Choose White on Black">>$README
	echo "NOTE: If the remote desktop ever seens locked or will not accept keystrokes, press the alt key. When you alt+tab away, the alt key stays pressed.">>$README

	mkdir /home/$OSUSER/dev
	mkdir /home/$OSUSER/dev/downloads
	mkdir /home/$OSUSER/dev/plugins

	# get eclipse IDE
	wget $ECLIPSESOURCEPATH -P /home/$OSUSER/dev/downloads
	tar -zxvf /home/$OSUSER/dev/downloads/eclipse-jee-kepler-SR1-linux-gtk-x86_64.tar.gz -C /home/$OSUSER/dev/

	# Create shortcut with appropriate command arguments in base eclipse directory - copy this file to your Desktop when you login.
	echo "[Desktop Entry]">/home/$OSUSER/dev/launchEclipse.desktop
	echo "Encoding=UTF-8">> /home/$OSUSER/dev/launchEclipse.desktop
	echo "Type=Application">> /home/$OSUSER/dev/launchEclipse.desktop
	echo "Name=eclipse">> /home/$OSUSER/dev/launchEclipse.desktop
	echo "Name[en_US]=eclipse">> /home/$OSUSER/dev/launchEclipse.desktop
	echo "Icon=/home/$OSUSER/dev/eclipse/icon.xpm">> /home/$OSUSER/dev/launchEclipse.desktop
	echo "Exec=/home/$OSUSER/dev/eclipse/eclipse  -vmargs -Xmx512M">> /home/$OSUSER/dev/launchEclipse.desktop
	echo "Comment[en_US]=">> /home/$OSUSER/dev/launchEclipse.desktop

	# create a shortcut to see what vnc sessions are open (used for XRDP remote desktop)
	sudo sed -i "$ a\alias wvnc='sudo netstat -tulpn | grep Xvnc'" /home/$OSUSER/.bashrc
	sudo sed -i "$ a\alias mateout='mate-session-save --force-logout'" /home/$OSUSER/.bashrc

	echo "">>$README
	echo "">>$README
	echo "A clean or prestine copy of the iDempiere code is downloaded to /home/$OSUSER/dev/idempiere">>$README
	echo "A working copy of iDempiere's code is downloaded to /home/$OSUSER/dev/myexperiment">>$README
	# get idempiere code
	echo "HERE: Installing iDempiere via mercurial"
	cd /home/$OSUSER/dev
	hg clone https://bitbucket.org/idempiere/idempiere
	# create a copy of the idempiere code named myexperiment. Use the myexperiment repostitory and not the idempiere (pristine)
	hg clone idempiere myexperiment
	cd /home/$OSUSER/dev/myexperiment
	# create a targetPlatform directory for eclipse - used when materializing the proejct
	mkdir /home/$OSUSER/dev/myexperiment/targetPlatform
	echo "HERE END: Installing iDempiere via mercurial"

	#if not bleeding edge
	if [[ $JENKINSPROJECT == "iDempiere"$IDEMPIERE_VERSION"Daily" ]]
	then
		echo "">>$README
		echo "">>$README
		echo "The working copy of iDempiere code in /home/$OSUSER/dev/myexperiment has been updated to verion $IDEMPIERE_VERSION">>$README
		echo "The script downloaded binaries from the jenkins build: $JENKINSPROJECT">>$README
		hg update -r release-"$IDEMPIERE_VERSION"
	fi

	# go back to home directory
	cd

	echo "">>$README
	echo "">>$README
	echo "This section discusses how to build iDempiere in Eclipse">>$README
	echo "STEP 1">>$README
	echo "To launch eclipse, copy the file named launchEclipse in the /home/$OSUSER/dev/ folder to your desktop.">>$README
	echo "Open Eclipse.">>$README
	echo "Choose the myexperiment folder as your workspace when eclipse launches.">>$README
	echo "Click on Help menu ==> Add New Software menu item ==> click the Add button.">>$README
	echo "Add the mercurial and buckminster plugins.">>$README
	echo " ---> Mercurial">>$README
	echo " ------> http://mercurialeclipse.eclipselabs.org.codespot.com/hg.wiki/update_site/stable">>$README
	echo " ------> choose mercurial but not windows binaries">>$README
	echo " ---> Buckminster">>$README
	echo " ------> http://download.eclipse.org/tools/buckminster/updates-4.3">>$README
	echo " ------> choose Core, Maven, and PDE">>$README
	echo " ---> JasperStudio (Optional for Jasper Reports)">>$README
	echo " ------> http://jasperstudio.sf.net/updates">>$README
	echo " ------> note: use Report Design perspective when ready to create reports.">>$README
	echo "More detailed instructions for the following can be found at http://www.globalqss.com/wiki/index.php/IDempiere/Install_Prerequisites_on_Ubuntu">>$README
	echo "">>$README
	echo "">>$README
	echo "STEP 2">>$README
	echo "Click on Window > Preferences > Plug-in Development > Target Platform.">>$README
	echo "Create your target platform.">>$README
	echo "Click on File > Import > Buckminster > Materialize from Buckminster CQUERY.">>$README
	echo "Materialize the project. If you browse to org.adempiere.sdk-feature/adempiere.cquery (instead of MSPEC),">>$README
	echo " ---> eclipse will automatically build the workspace as part of the buckminster import process">>$README
	echo "If you ger errors when running install.app, try cleaning the project. Menu->Project->Clean">>$README
	echo "">>$README
	echo "">>$README
	echo "Important Note!">>$README
	echo "iDempiere is installed twice: first as a service, and second in eclipse.">>$README
	echo "If you run the iDempiere server through eclipse, make sure you stop the iDempiere service using 'sudo service idempiere stop' first.">>$README

	echo "HERE END: Install desktop components because IS_INSTALL_DESKTOP == Y"

fi #end if IS_INSTALL_DESKTOP = Y


# Move postgresql files to a separate device.
# This is incredibly useful if you are running in aws where if the server dies, you lose your work.
# By moving the DB files to an EBS drive, you help ensure you data will survive a server crash or shutdown.
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

	sudo -u postgres service postgresql stop

	#map the data direcory
	sudo mkdir /vol/var
	sudo mv /var/lib/postgresql/$PGVERSION/main /vol/var
	sudo mkdir /var/lib/postgresql/$PGVERSION/main
	echo "/vol/var/main /var/lib/postgresql/$PGVERSION/main     none bind" | sudo tee -a /etc/fstab
	sudo mount /var/lib/postgresql/$PGVERSION/main

	#map the conf directory
	sudo mkdir /vol/etc
	sudo mv /etc/postgresql/$PGVERSION/main /vol/etc
	sudo mkdir /etc/postgresql/$PGVERSION/main
	echo "/vol/etc/main /etc/postgresql/$PGVERSION/main     none bind" | sudo tee -a /etc/fstab
	sudo mount /etc/postgresql/$PGVERSION/main

	sudo -u postgres service postgresql start

	echo "HERE END: Moving DB because IS_MOVE_DB == Y"

fi #end if IS_MOVE_DB==Y

# Install iDempiere
if [[ $IS_INSTALL_ID == "Y" ]]
then
	echo "HERE: Installing iDemipere because IS_INSTALL_ID == Y"
	echo "">>$README
	echo "">>$README
	echo "iDemipere is installed on this server">>$README
	echo "">>$README
	echo "">>$README
	echo "Note: The below command helps you prevent other users from seeing your home directory">>$README
	echo "  sudo chmod -R o-rx /home/$OSUSER">>$README

	# create IDEMPIEREUSER user and group
	sudo adduser $IDEMPIEREUSER --system

	# create database password file for iDempiere user
	sudo echo "localhost:*:*:adempiere:$DBPASS">>$HOME_DIR/.pgpass
	sudo chown $IDEMPIEREUSER: $HOME_DIR/.pgpass
	sudo -u $IDEMPIEREUSER chmod 600 $HOME_DIR/.pgpass
	sudo mv $HOME_DIR/.pgpass /home/$IDEMPIEREUSER/

	#the following is no longer applicable since iDempiere is now a system user
	#echo "To add your OS user to the iDempiere group, issue the following commands">>$README
	#echo "	sudo usermod -a -G $IDEMPIEREUSER YOUR_USER_NAME_HERE">>$README

	sudo apt-get --yes install openjdk-6-jdk
	if [[ $IS_INSTALL_DB == "N" ]]
	then
		echo "HERE: install postgresql client tools"
		sudo apt-get -y install postgresql-client
	fi

	# make installpath
	# clone id_installer againt to chuboe_isntallpath

	mkdir $HOME_DIR/installer_`date +%Y%m%d`
	mkdir $HOME_DIR/installer_client_`date +%Y%m%d`
	sudo mkdir $INSTALLPATH

	sudo wget $IDEMPIERESOURCEPATH -P $HOME_DIR/installer_`date +%Y%m%d`
	sudo wget $IDEMPIERECLIENTPATH -P $HOME_DIR/installer_client_`date +%Y%m%d`
	if [[ $IS_BLEED_EDGE == "Y" ]]
	then
		echo "HERE: IS_BLEED_EDGE == Y"
		sudo wget $IDEMPIERESOURCEPATHBLEEDDETAIL -P $HOME_DIR/installer_`date +%Y%m%d` -O iDempiere_Version.html
	fi

	# check if file downloaded
	RESULT=$(ls -l $HOME_DIR/installer_`date +%Y%m%d`/*64.zip | wc -l)
	if [ $RESULT -ge 1 ]; then
        	echo "HERE: file exists"
	else
		echo "HERE: file does not exist. Stopping script!"
		echo "HERE: If pulling Bleeding Copy, check http://jenkins.idempiere.com/job/iDempiere"$IDEMPIERE_VERSION"Daily/ to see if the daily build failed"
		echo "">>$README
		echo "">>$README
		echo "ERROR: The iDempiere binary file download failed. The file does not exist locally. Stopping script!">>$README
		echo "If pulling Bleeding Copy, check http://jenkins.idempiere.com/job/iDempiere"$IDEMPIERE_VERSION"Daily/ to see if the daily build failed.">>$README
		# nano /home/$OSUSER/$README
		exit 1
	fi

	sudo unzip $HOME_DIR/installer_`date +%Y%m%d`/idempiereServer.gtk.linux.x86_64.zip -d $HOME_DIR/installer_`date +%Y%m%d`
	cd $HOME_DIR/installer_`date +%Y%m%d`/idempiere.gtk.linux.x86_64/idempiere-server/
	cp -r * $INSTALLPATH
	cd $INSTALLPATH

	echo "">>$README
	echo "">>$README
	echo "The following section applies to the iDempiere Swing client.">>$README
	echo "To use the swing client, unzip it by issuing the command:">>$README
	echo "---> unzip /home/$OSUSER/installer_client_`date +%Y%m%d`/idempiereClient.gtk.linux.x86_64.zip -d /home/$OSUSER/installer_client_`date +%Y%m%d`">>$README
	echo "---> change directory to your adempiere-client directory in your new unzipped folder.">>$README
	echo "---> Launch the client using ./adempiere-client.sh">>$README
	echo "---> At the login screen, click on the server field.">>$README
	echo "---> In the server dialog, set the Application Host (for example: localhost) to your web server,">>$README
	echo "------> and set the Application Port to 8443.">>$README
	echo "------> Test the application server and database then click the green check.">>$README
	echo "To install swing clients for other OS's, go to:">>$README
	echo "---> Bleeding Edge: http://www.globalqss.com/wiki/index.php/IDempiere/Downloading_Hot_Installers">>$README
	echo "---> Current Stable Release: http://sourceforge.net/projects/idempiere/files/v"$IDEMPIERE_VERSION"/swing-client/">>$README
	echo "">>$README
	echo "">>$README
	echo "This section applies to offsite backups.">>$README
	echo "The utilities directory includes some very useful scipts: $CHUBOE_UTIL_HG/utils">>$README
	echo "Issue the following commands to enable s3cmd and create an iDempiere backup bucket in S3.">>$README
	echo "---> s3cmd --configure">>$README
	echo "------> get your access key and secred key by logging into your AWS account">>$README
	echo "------> enter a password. Chose something different than your AWS password. Write it down!!">>$README
	echo "------> Accept the default path to GPG">>$README
	echo "------> Answer yes to HTTPS">>$README
	echo "Create your new S3 backup bucket">>$README
	echo "---> s3cmd mb s3://iDempiere_backup">>$README
	echo "IMPORTANT NOTE: the above S3 bucket name might not be available. If not, use something like iDempiere_backup_YOURNAME.">>$README
	echo "If you do need to change the bucket name, make sure both the backup and the restore scripts are updated accordingly.">>$README
	echo "">>$README
	echo "">>$README
	echo "To update your server's timezone, run this command:">>$README
	echo "---> sudo dpkg-reconfigure tzdata">>$README

echo "HERE: Launching console-setup.sh"
#not indented because of file input
sh console-setup.sh <<!













2
$PIP



$DBPASS
$DBPASS
mail.dummy.com




!
cd utils
sh RUN_ImportIdempiere.sh <<!

!
#end of file input
echo "HERE END: Launching console-setup.sh"

	# add pgcrypto to support apache based authentication
	echo "HERE: pgcrypto extension"
	sudo -u idempiere psql -U adempiere -d idempiere -c "CREATE EXTENSION pgcrypto"

	echo "HERE: Creating chuboe_utils"
	cd 
	echo "">>$README
	echo "">>$README
	mkdir $CHUBOE_UTIL
	cd $CHUBOE_UTIL
	sudo hg clone https://bitbucket.org/cboecking/idempiere-installation-script

	sudo sed -i "s|VALUE_GOES_HERE|$JENKINSPROJECT|" $CHUBOE_UTIL_HG_PROP/JENKINS_PROJECT.txt
	sudo sed -i "s|VALUE_GOES_HERE|$IDEMPIERE_VERSION|" $CHUBOE_UTIL_HG_PROP/IDEMPIERE_VERSION.txt

	#prevent the backup's annoying 30 second delay
	sed -i "s|sleep 30|#sleep 30|" $INSTALLPATH/utils/myDBcopy.sh

	# if server is dedicated to iDempiere, give it more power
	TOTAL_MEMORY=$(grep MemTotal /proc/meminfo | awk '{printf("%.0f\n", $2 / 1024)}')
	echo "total memory in MB="$TOTAL_MEMORY
	AVAIL_MEMORY=$(echo "$TOTAL_MEMORY*0.70" | bc)
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
		sudo sed -i "s|-XX:MaxPermSize|-Xmx"$XMX"m -XX:MaxPermSize|" $INSTALLPATH/idempiere-server.sh
		# use the following command to confirm the above setting took: sudo -u idempiere jps -v localhost
		echo "HERE END: lots of memory and dedicated idempiere server"
	fi

	#hand ownership of iDempiere direcetory to the idempiere user
	sudo chown -R $IDEMPIEREUSER: $INSTALLPATH
	sudo chown -R $IDEMPIEREUSER: $CHUBOE_UTIL
	sudo chmod -R 0640 $INSTALLPATH
	sudo chmod -R 0640 $CHUBOE_UTIL
	sudo chmod -R +x $CHUBOE_UTIL_HG/*.sh
	sudo chmod 600 $INSTALLPATH/idempiereEnv.properties

	# give $OSUSER write access to idempiere server directory through the $IDEMPIEREUSER group
	# HERE NOTE: You must restart your ssh session to be able to interact with the idempiere tools.
	#TODO check to see if this still works since idempiere is a system user
	sudo find /opt/idempiere-server -type d -exec chmod 775 {} \;

	echo "HERE: configure apache to present webui on port 80 - reverse proxy"
	# install apache2 if missed during db/phpgadmin
	if [[ $IS_INSTALL_DB == "N" ]]
	then 
		sudo apt-get install -y apache2
	fi

	# copy the iDempiere apache2 configuration file
	sudo cp $SCRIPTPATH/web/000-webui.conf /etc/apache2/sites-enabled
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

	echo "HERE END: Installing iDemipere because IS_INSTALL_ID == Y"

fi #end if $IS_INSTALL_ID == "Y"

# Run iDempiere
if [[ $IS_LAUNCH_ID == "Y" ]]
then
	echo "HERE: IS_LANUNCH_ID == Y"
	echo "HERE: setting iDempiere to start on boot"
	echo "">>$README
	echo "">>$README
	echo "iDempiere is started and is set to start on system boot">>$README
	sudo -u idempiere cp $SCRIPTPATH/stopServer.sh $INSTALLPATH/utils
	sudo cp $SCRIPTPATH/$INITDNAME /etc/init.d/
	sudo chmod +x /etc/init.d/$INITDNAME
	sudo update-rc.d $INITDNAME defaults
	sudo /etc/init.d/$INITDNAME start
	echo "HERE END: IS_LANUNCH_ID == Y"
fi

sudo chmod -R 0555 $HOME_DIR

echo "">>$README
echo "">>$README
echo "Contratulations - the script seems to have executed successfully.">>$README