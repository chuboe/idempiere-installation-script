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
# 1.4 added better user instruction and added support for -b (s3 backup)

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
	-b	Name of s3 bucket for backups
	-P	DB password
	-l	Launch iDempiere as service
	-u	Specify a username other than ubuntu
	-B	Use bleeding edge copy of iDempiere
	-D	Install desktop development tools

Outstanding actions:
* Capture when a parameter begins with '-' - in other words, the user did not add the argument modifier
* Add better error checking
* Remove some of the hardcoded variables
* Add support for -s option to suppress services.
  - Doing so will require a code change to AdempiereServerMgr.java (in iDempiere).
  - This option will allow you to run multiple WebUI servers behind a load balancer.
* Add support for pgpool. This option will allow you to read from multiple database servers across multiple aws availability zones.

EOF
}

#initialize variables with default values - these values might be overwritten during the next section based on command options
IS_INSTALL_DB="Y"
IS_INSTALL_SERVICE="Y"
IS_MOVE_DB="N"
IS_INSTALL_ID="Y"
IS_LAUNCH_ID="N"
IS_S3BACKUP="N"
IS_INSTALL_DESKTOP="N"
PIP="localhost"
DEVNAME="NONE"
DBPASS="NONE"
S3BUCKET="NONE"
INSTALLPATH="/opt/idempiere-server/"
INITDNAME="idempiere"
SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
IDEMPIERESOURCEPATH="http://sourceforge.net/projects/idempiere/files/v1.0c/server/idempiereServer.gtk.linux.x86_64.zip"
IDEMPIERESOURCEPATHBLEED="http://jenkins.idempiere.com/job/iDempiereDaily/ws/buckminster.output/org.adempiere.server_1.0.0-eclipse.feature/idempiereServer.gtk.linux.x86_64.zip"
ECLIPSESOURCEPATH="http://download.springsource.com/release/ECLIPSE/kepler/SR1/eclipse-jee-kepler-SR1-linux-gtk-x86_64.tar.gz"
OSUSER="ubuntu"
README="idempiere_installer_feedback.txt"
OUTPUT="output.txt"

# process the specified options
# the colon after the letter specifies there should be text with the option
while getopts "hsp:e:ib:P:lu:BD" OPTION
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

		b)	#specify s3 bucket for backup
			IS_S3BACKUP="Y"
			S3BUCKET=$OPTARG;;

		P)	#database password
			DBPASS=$OPTARG;;

		l)	#launch iDempiere
			IS_LAUNCH_ID="Y";;

		u)	#user
			OSUSER=$OPTARG;;

		B)	#use bleeding edge copy of iDempiere
			IDEMPIERESOURCEPATH=$IDEMPIERESOURCEPATHBLEED;;

		D)	#install desktop development components
			IS_INSTALL_DESKTOP="Y";;
	esac
done

# show variables to the user (debug)
echo "if you want to find for echoed values, search for HERE:"&>>/home/$OSUSER/$OUTPUT
echo "HERE: print variables"&>>/home/$OSUSER/$OUTPUT
echo "Install DB=" $IS_INSTALL_DB&>>/home/$OSUSER/$OUTPUT
echo "Move DB="$IS_MOVE_DB&>>/home/$OSUSER/$OUTPUT
echo "Install iDempiere="$IS_INSTALL_ID&>>/home/$OSUSER/$OUTPUT
echo "Install iDempiere Scheduled Services (not implemented)="$IS_INSTALL_SERVICE&>>/home/$OSUSER/$OUTPUT
echo "Install Desktop="$IS_INSTALL_DESKTOP&>>/home/$OSUSER/$OUTPUT
echo "Backup to S3="$IS_S3BACKUP&>>/home/$OSUSER/$OUTPUT
echo "Database IP="$PIP&>>/home/$OSUSER/$OUTPUT
echo "MoveDB Device Name="$DEVNAME&>>/home/$OSUSER/$OUTPUT
echo "DB Password="$DBPASS&>>/home/$OSUSER/$OUTPUT
echo "Launch iDempiere as a service="$IS_LAUNCH_ID&>>/home/$OSUSER/$OUTPUT
echo "S3 Bucket name="$S3BUCKET&>>/home/$OSUSER/$OUTPUT
echo "Install Path="$INSTALLPATH&>>/home/$OSUSER/$OUTPUT
echo "InitDName="$INITDNAME&>>/home/$OSUSER/$OUTPUT
echo "ScriptName="$SCRIPTNAME&>>/home/$OSUSER/$OUTPUT
echo "ScriptPath="$SCRIPTPATH&>>/home/$OSUSER/$OUTPUT
echo "OSUser="$OSUSER&>>/home/$OSUSER/$OUTPUT
echo "iDempiereSourcePath="$IDEMPIERESOURCEPATH&>>/home/$OSUSER/$OUTPUT
echo "EclipseSourcePath="$ECLIPSESOURCEPATH&>>/home/$OSUSER/$OUTPUT
echo "Distro details:"&>>/home/$OSUSER/$OUTPUT
cat /etc/*-release&>>/home/$OSUSER/$OUTPUT

# Create file to give user feedback about installation
echo "">/home/$OSUSER/$README
echo "">/home/$OSUSER/$OUTPUT

# Check to ensure DB password is set
if [[ $DBPASS == "NONE" && $IS_INSTALL_DB == "Y"  ]]
then
	echo "HERE: Must set DB Password if installing DB!!"&>>/home/$OSUSER/$OUTPUT
	echo "Must set DB Password if installing DB!! Stopping script!">>/home/$OSUSER/$README
	nano /home/$OSUSER/$README
	exit 1
fi

# Check to see if S3 Bucket is specified when $IS_S3BACKUP == Y
if [[ $S3BUCKET == "NONE" && $IS_S3BACKUP == "Y"  ]]
then
	echo "HERE: Must specify S3 Bucket when setting backup argument!!"&>>/home/$OSUSER/$OUTPUT
	echo "Must specify S3 Bucket when setting backup argument!! Stopping script!">>/home/$OSUSER/$README
	nano /home/$OSUSER/$README
	exit 1
fi

# You can only perform the backup if you are installing idempiere
if [[ $IS_INSTALL_ID == "N" && $IS_S3BACKUP == "Y"  ]]
then
	echo "HERE: The backup script must be installed with iDempiere!!"&>>/home/$OSUSER/$OUTPUT
	echo "The backup script must be installed with iDempiere!! Stopping script!">>/home/$OSUSER/$README
	nano /home/$OSUSER/$README
	exit 1
fi

# Check if user exists
RESULT=$(id -u $OSUSER)
if [ $RESULT -ge 0 ]; then
	echo "HERE: OSUser exists">>/home/$OSUSER/$OUTPUT
else
	echo "HERE: OSUser does not exist. Stopping script!"">>/home/$OSUSER/$OUTPUT
	echo "OSUser does not exist. Stopping script!">>/home/$OSUSER/$README
	nano /home/$OSUSER/$README
	exit 1
fi

# update apt package manager
sudo apt-get --yes update&>>/home/$OSUSER/$OUTPUT

# update locate database
sudo updatedb&>>/home/$OSUSER/$OUTPUT

# install useful utilities
sudo apt-get --yes install unzip htop s3cmd expect&>>/home/$OSUSER/$OUTPUT

# install database
if [[ $IS_INSTALL_DB == "Y" ]]
then
	echo "HERE: Installing DB because IS_INSTALL_DB == Y">>/home/$OSUSER/$OUTPUT
	echo "Installing DB because IS_INSTALL_DB == Y">>/home/$OSUSER/$README
	sudo apt-get --yes install postgresql postgresql-contrib phppgadmin&>>/home/$OSUSER/$OUTPUT
	sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '"$DBPASS"';"&>>/home/$OSUSER/$OUTPUT

	# The following commands update postgresql to listen for all
	# connections (not just localhost). Make sure your firewall
	# prevents outsiders for connecting to your server.
	sudo sed -i '$ a\host   all     all     0.0.0.0/0       md5' /etc/postgresql/9.1/main/pg_hba.conf&>>/home/$OSUSER/$OUTPUT
	sudo sed -i 's/#listen_addresses = '"'"'localhost'"'"'/listen_addresses = '"'"'*'"'"'/' /etc/postgresql/9.1/main/postgresql.conf&>>/home/$OSUSER/$OUTPUT

	sudo -u postgres service postgresql restart&>>/home/$OSUSER/$OUTPUT

	# The following commands update phppgadmin to allow all IPs to connect.
	# Make sure your firewall prevents outsiders from connecting to your server.
	sudo sed -i 's/# allow from all/allow from all/' /etc/apache2/conf.d/phppgadmin&>>/home/$OSUSER/$OUTPUT
	sudo service apache2 restart&>>/home/$OSUSER/$OUTPUT

	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "SECURITY NOTICE: phppgadmin has been installed on port 80.">>/home/$OSUSER/$README
	echo "Make sure this port is blocked from external traffic as a security mesaure.">>/home/$OSUSER/$README

fi #end if IS_INSTALL_DB==Y

# install desktop components
if [[ $IS_INSTALL_DESKTOP == "Y" ]]
then
	echo "HERE: Install desktop components because IS_INSTALL_DESKTOP == Y"&>>/home/$OSUSER/$OUTPUT
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "Installing desktop components because IS_INSTALL_DESKTOP == Y">>/home/$OSUSER/$README
	sudo apt-get install -y lubuntu-desktop xrdp&>>/home/$OSUSER/$OUTPUT
	# note that sed can use any delimiting character. Here I use the '=' instead of the slash
	# set is a tool to add or replace text in a file
	sudo sed -i 's=. /etc/X11/Xsession=#. /etc/X11/Xsession=' /etc/xrdp/startwm.sh&>>/home/$OSUSER/$OUTPUT
	sudo sed -i '$ a\startlubuntu' /etc/xrdp/startwm.sh&>>/home/$OSUSER/$OUTPUT
	echo "HERE: set the ubuntu password using passwd command to log in remotely"&>>/home/$OSUSER/$OUTPUT
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "ACTION REQUIRED: set the ubuntu password using 'passwd' command to log in remotely">>/home/$OSUSER/$README
	echo "--------> to set the password for the ubuntu user: 'sudo passwd ubuntu'">>/home/$OSUSER/$README
	echo "--------> the script installed 'xrdp' with allows you to use Windows Remote Desktop to connect.">>/home/$OSUSER/$README
	mkdir /home/$OSUSER/dev&>>/home/$OSUSER/$OUTPUT
	mkdir /home/$OSUSER/dev/downloads&>>/home/$OSUSER/$OUTPUT
	mkdir /home/$OSUSER/dev/plugins&>>/home/$OSUSER/$OUTPUT

	# get eclipse IDE
	wget $ECLIPSESOURCEPATH -P /home/$OSUSER/dev/downloads&>>/home/$OSUSER/$OUTPUT
	tar -zxvf /home/$OSUSER/dev/downloads/eclipse-jee-kepler-SR1-linux-gtk-x86_64.tar.gz -C /home/$OSUSER/dev/&>>/home/$OSUSER/$OUTPUT

	# Create shortcut with appropriate command arguments in base eclipse directory - copy this file to your Desktop when you login.
	echo "">/home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\[Desktop Entry]' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Encoding=UTF-8' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Type=Application' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Name=eclipse' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Name[en_US]=eclipse' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Icon=/home/ubuntu/dev/eclipse/icon.xpm' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Exec=/home/ubuntu/dev/eclipse/eclipse  -vmargs -Xmx512M' /home/$OSUSER/dev/launchEclipse
	sudo sed -i '$ a\Comment[en_US]=' /home/$OSUSER/dev/launchEclipse
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "SUGGESTION: copy the file named launchEclipse in the /home/$OSUSER/dev/ folder to your desktop.">>/home/$OSUSER/$README

	# get idempiere code
	cd /home/$OSUSER/dev&>>/home/$OSUSER/$OUTPUT
	hg clone https://bitbucket.org/idempiere/idempiere&>>/home/$OSUSER/$OUTPUT
	# create a copy of the idempiere code named myexperiment. Use the myexperiment repostitory and not the idempiere (pristine)
	hg clone idempiere myexperiment&>>/home/$OSUSER/$OUTPUT
	# create a targetPlatform directory for eclipse - used when materializing the proejct
	mkdir /home/$OSUSER/dev/myexperiment/targetPlatform&>>/home/$OSUSER/$OUTPUT

	# go back to home directory
	cd&>>/home/$OSUSER/$OUTPUT

	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "When the script finishes, log in via remote desktop and open launchEclipse.">>/home/$OSUSER/$README
	echo "Choose the myexperiment folder as your workspace.">>/home/$OSUSER/$README
	echo "Add the mercurial and buckminster plugins.">>/home/$OSUSER/$README
	echo "More detailed instructions for the following can be found at http://www.globalqss.com/wiki/index.php/IDempiere/Install_Prerequisites_on_Ubuntu">>/home/$OSUSER/$README
	echo " --> Mercurial">>/home/$OSUSER/$README
	echo " ------> http://cbes.javaforge.com/update">>/home/$OSUSER/$README
	echo " ------> choose mercurial but not windows binaries">>/home/$OSUSER/$README
	echo " --> Buckminster">>/home/$OSUSER/$README
	echo " ------> http://download.eclipse.org/tools/buckminster/updates-4.3">>/home/$OSUSER/$README
	echo " ------> choose Core, Maven, and PDE">>/home/$OSUSER/$README
	echo "Create your target platform.">>/home/$OSUSER/$README
	echo "Materialize the project. If you use CQUERY (instead of MSPEC),">>/home/$OSUSER/$README
	echo " --> it seems to automatically build the workspace">>/home/$OSUSER/$README
	echo "If you ger errors when running install.app, try cleaning the project. Menu->Project->Clean">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "Please note that iDempiere is installed twice: first as a service, and second in eclipse.">>/home/$OSUSER/$README
	echo "If you run the iDempiere server through eclipse, make sure you stop the iDempiere service using 'sudo service idempiere stop' first.">>/home/$OSUSER/$README


fi #end if IS_INSTALL_DESKTOP = Y


# Move postgresql files to a separate device.
# This is incredibly useful if you are running in aws where if the server dies, you lose your work.
# By moving the DB files to an EBS drive, you help ensure you data will survive a server crash or shutdown.
# Make note that Ubuntu renames the device from s.. to xv.. For example, device sdh will get renamed to xvdh.
# The below code makes the mapping persist after a reboot by creating the fstab entry.
if [[ $IS_MOVE_DB == "Y" ]]
then
	echo "HERE: Moving DB because IS_MOVE_DB == Y"&>>/home/$OSUSER/$OUTPUT
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "Moving DB because IS_MOVE_DB == Y">>/home/$OSUSER/$README
	sudo apt-get update&>>/home/$OSUSER/$OUTPUT
	sudo apt-get install -y xfsprogs&>>/home/$OSUSER/$OUTPUT
	#sudo apt-get install -y postgresql #uncomment if you need the script to install the db
	sudo mkfs.ext4 /dev/$DEVNAME&>>/home/$OSUSER/$OUTPUT
	echo "/dev/"$DEVNAME" /vol ext4 noatime 0 0" | sudo tee -a /etc/fstab&>>/home/$OSUSER/$OUTPUT
	sudo mkdir -m 000 /vol&>>/home/$OSUSER/$OUTPUT
	sudo mount /vol&>>/home/$OSUSER/$OUTPUT

	sudo -u postgres service postgresql stop&>>/home/$OSUSER/$OUTPUT

	#map the data direcory
	sudo mkdir /vol/var&>>/home/$OSUSER/$OUTPUT
	sudo mv /var/lib/postgresql/9.1/main /vol/var&>>/home/$OSUSER/$OUTPUT
	sudo mkdir /var/lib/postgresql/9.1/main&>>/home/$OSUSER/$OUTPUT
	echo "/vol/var/main /var/lib/postgresql/9.1/main     none bind" | sudo tee -a /etc/fstab&>>/home/$OSUSER/$OUTPUT
	sudo mount /var/lib/postgresql/9.1/main&>>/home/$OSUSER/$OUTPUT

	#map the conf directory
	sudo mkdir /vol/etc&>>/home/$OSUSER/$OUTPUT
	sudo mv /etc/postgresql/9.1/main /vol/etc&>>/home/$OSUSER/$OUTPUT
	sudo mkdir /etc/postgresql/9.1/main&>>/home/$OSUSER/$OUTPUT
	echo "/vol/etc/main /etc/postgresql/9.1/main     none bind" | sudo tee -a /etc/fstab&>>/home/$OSUSER/$OUTPUT
	sudo mount /etc/postgresql/9.1/main&>>/home/$OSUSER/$OUTPUT

	sudo -u postgres service postgresql start&>>/home/$OSUSER/$OUTPUT

fi #end if IS_MOVE_DB==Y

# Install iDempiere
if [[ $IS_INSTALL_ID == "Y" ]]
then
	echo "HERE: Installing iDemipere because IS_INSTALL_ID == Y"&>>/home/$OSUSER/$OUTPUT
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "Installing iDemipere because IS_INSTALL_ID == Y">>/home/$OSUSER/$README
	sudo apt-get --yes install openjdk-6-jdk&>>/home/$OSUSER/$OUTPUT
	if [[ $IS_INSTALL_DB == "N" ]]
	then
		#install postgresql client tools
		sudo apt-get -y install postgresql-client&>>/home/$OSUSER/$OUTPUT
	fi

	mkdir /home/$OSUSER/installer_`date +%Y%m%d`&>>/home/$OSUSER/$OUTPUT
	sudo mkdir $INSTALLPATH&>>/home/$OSUSER/$OUTPUT
	sudo chown $OSUSER:$OSUSER $INSTALLPATH&>>/home/$OSUSER/$OUTPUT
	wget $IDEMPIERESOURCEPATH -P /home/$OSUSER/installer_`date +%Y%m%d`&>>/home/$OSUSER/$OUTPUT

	# check if file downloaded
	RESULT=$(ls -l /home/$OSUSER/installer_`date +%Y%m%d`/*64.zip | wc -l)
	if [ $RESULT -ge 1 ]; then
        	echo "HERE: file exists"&>>/home/$OSUSER/$OUTPUT
	else
        	echo "HERE: file does not exist. Stopping script!"&>>/home/$OSUSER/$OUTPUT
		echo "HERE: If pulling Bleeding Copy, check http://jenkins.idempiere.com/job/iDempiereDaily/ to see if the daily build failed"&>>/home/$OSUSER/$OUTPUT
		echo "">>/home/$OSUSER/$README
		echo "">>/home/$OSUSER/$README
        	echo "File does not exist. Stopping script!">>/home/$OSUSER/$README
        	echo "If pulling Bleeding Copy, check http://jenkins.idempiere.com/job/iDempiereDaily/ to see if the daily build failed">>/home/$OSUSER/$README
		nano /home/$OSUSER/$README
	        exit 1
	fi

	unzip /home/$OSUSER/installer_`date +%Y%m%d`/idempiereServer.gtk.linux.x86_64.zip -d /home/$OSUSER/installer_`date +%Y%m%d`&>>/home/$OSUSER/$OUTPUT
	cd /home/$OSUSER/installer_`date +%Y%m%d`/idempiere.gtk.linux.x86_64/idempiere-server/&>>/home/$OSUSER/$OUTPUT
	cp -r * $INSTALLPATH&>>/home/$OSUSER/$OUTPUT
	cd $INSTALLPATH&>>/home/$OSUSER/$OUTPUT
	mkdir log&>>/home/$OSUSER/$OUTPUT

	# install S3 backup script
	if [[ $IS_S3BACKUP == "Y" ]]
	then
		echo "HERE: Updating iDempiere backup because IS_S3BACKUP == Y"&>>/home/$OSUSER/$OUTPUT
		echo "Updating iDempiere backup because IS_S3BACKUP == Y">>/home/$OSUSER/$README
		# add the s3cmd command as the last step to the existing backup script
		sed -i 's=sleep 30=s3cmd put \$IDEMPIERE_HOME/data/ExpDat\$DATE.jar s3://$S3BUCKET=' /$INSTALLPATH/utils/myDBcopy.sh
		echo "sleep 20">>/$INSTALLPATH/utils/myDBcopy.sh

		#write out current crontab - schedule backups
		crontab -l > mycron
		#echo new cron into cron file - 0 minute, 2nd hour, every day, every month, every day of the week
		echo "00 02 * * * /$INSTALLPATH/utils/RUN_DBExport.sh" >> mycron
		#install new cron file
		crontab mycron
		rm mycron

		# give instructions to configure s3cmd
		echo "">>/home/$OSUSER/$README
                echo "">>/home/$OSUSER/$README
                echo "ACTION REQUIRED: To use S3 backup via s3cmd, you need to perform the following:">>/home/$OSUSER/$README
                echo "--> issue command: s3cmd --configure">>/home/$OSUSER/$README
		echo "----> get your access key and secred key by logging into your AWS account">>/home/$OSUSER/$README
		echo "--> issue command to create your S3 bucket: s3cmd mb s3://$S3BUCKET">>/home/$OSUSER/$README
                echo "">>/home/$OSUSER/$README
	fi #end if ISBACKUP == Y

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

fi #end if $IS_INSTALL_ID == "Y"

# Run iDempiere
echo "HERE: IS_LAUNCH_ID="$IS_LAUNCH_ID&>>/home/$OSUSER/$OUTPUT
if [[ $IS_LAUNCH_ID == "Y" ]]
then
	echo "HERE: setting iDempiere to start on boot"&>>/home/$OSUSER/$OUTPUT
	echo "">>/home/$OSUSER/$README
	echo "">>/home/$OSUSER/$README
	echo "iDempiere set to start on boot">>/home/$OSUSER/$README
	sudo cp $SCRIPTPATH/stopServer.sh $INSTALLPATH/utils&>>/home/$OSUSER/$OUTPUT
	sudo cp $SCRIPTPATH/$INITDNAME /etc/init.d/&>>/home/$OSUSER/$OUTPUT
	sudo chmod +x /etc/init.d/$INITDNAME&>>/home/$OSUSER/$OUTPUT
	sudo update-rc.d $INITDNAME defaults&>>/home/$OSUSER/$OUTPUT

	sudo /etc/init.d/$INITDNAME start&>>/home/$OSUSER/$OUTPUT
fi

# show results to user
nano /home/$OSUSER/$README

# TODO: Need section for S3 backup
# Consider modifying the existing backup script
# to issue the s3cmd command to push the newly
# create file the desired s3 bucket
