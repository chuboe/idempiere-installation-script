#!/bin/bash

# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
# idempiere_install_script_master_linux.sh
# 1.0 initial release

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
	-b	Name of s3 bucket for backups (not implemented yet)
	-P	DB password
	-l	launch iDempiere with nohup

Outstanding actions:
* Add better error checking
* Remove some of the hardcoded variables
* Change wget to the upcoming stable release (when it comes out). Currently points to the development head.
* Default iDempiere to port 80
* Default iDempiere admin to 443
* Default phppgadmin to port to 80 if DB only install, 8080 otherwise if iDempiere is installed
* Make sure phppgadmin is running after the script executes (not just installed)
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
PIP="localhost"
DEVNAME="NONE"
DBPASS="NONE"
S3BUCKET="NONE"

# process the specified options
while getopts "hsp:e:ib:P:l" OPTION
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
			echo "NOTE: -b option not implemented yet!!";;

		P)	#database password
			DBPASS=$OPTARG;;

		l)	#launch iDempiere
			IS_LAUNCH_ID="Y";;
	esac
done

# show variables to the user (debug)
echo "Install DB=" $IS_INSTALL_DB
echo "Move DB="$IS_MOVE_DB
echo "Install iDempiere="$IS_INSTALL_ID
echo "Install iDempiere Services="$IS_INSTALL_SERVICE
echo "Database IP="$PIP
echo "MoveDB Device Name="$DEVNAME
echo "DB Password="$DBPASS
echo "Launch iDempiere with nohup"=$IS_LAUNCH_ID

#Check for known error conditions
if [[ $DBPASS == "NONE" && $IS_INSTALL_DB == "Y"  ]]
then
	echo "Must set DB Password if installing DB!!"
	exit 1
fi

# update apt package manager
sudo apt-get --yes update

# update locate database
sudo updatedb

# install useful utilities
sudo apt-get --yes install unzip htop s3cmd

# install database
if [[ $IS_INSTALL_DB == "Y" ]]
then
	echo "Installing DB because IS_INSTALL_DB == Y"
	sudo apt-get --yes install postgresql postgresql-contrib phppgadmin
	sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '"$DBPASS"';"
	sudo sed -i '$ a\host   all     all     0.0.0.0/0       md5' /etc/postgresql/9.1/main/pg_hba.conf
	sudo sed -i 's/#listen_addresses = '"'"'localhost'"'"'/listen_addresses = '"'"'*'"'"'/' /etc/postgresql/9.1/main/postgresql.conf
	sudo -u postgres service postgresql restart
fi #end if IS_INSTALL_DB==Y

# Move postgresql files to a separate device.
# This is incredibly useful if you are running in aws where if the server dies, you lose your work.
# By moving the DB files to an EBS drive, you help ensure you data will survive a server crash or shutdown.
# Make note that Ubuntu renames the device from s.. to xv.. For example, device sdh will get renamed to xvdh.
# The below code makes the mapping persist after a reboot by creating the fstab entry.
if [[ $IS_MOVE_DB == "Y" ]]
then
	echo "Moving DB because IS_MOVE_DB == Y"
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
	sudo mv /var/lib/postgresql/9.1/main /vol/var
	sudo mkdir /var/lib/postgresql/9.1/main
	echo "/vol/var/main /var/lib/postgresql/9.1/main     none bind" | sudo tee -a /etc/fstab
	sudo mount /var/lib/postgresql/9.1/main

	#map the conf directory
	sudo mkdir /vol/etc
	sudo mv /etc/postgresql/9.1/main /vol/etc
	sudo mkdir /etc/postgresql/9.1/main
	echo "/vol/etc/main /etc/postgresql/9.1/main     none bind" | sudo tee -a /etc/fstab
	sudo mount /etc/postgresql/9.1/main

	sudo -u postgres service postgresql start

fi #end if IS_MOVE_DB==Y

# Install iDempiere
if [[ $IS_INSTALL_ID == "Y" ]]
then
	echo "Installing iDemipere because IS_INSTALL_ID == Y"
	sudo apt-get --yes install openjdk-6-jdk
	if [[ $IS_INSTALL_DB == "N" ]]
	then
		#install postgresql client tools
		sudo apt-get -y install postgresql-client
	fi
	mkdir /home/ubuntu/installer_`date +%Y%m%d`
	wget http://jenkins.idempiere.com/job/iDempiereDaily/ws/buckminster.output/org.adempiere.server_1.0.0-eclipse.feature/idempiereServer.gtk.linux.x86_64.zip -P /home/ubuntu/installer_`date +%Y%m%d`
	unzip /home/ubuntu/installer_`date +%Y%m%d`/idempiereServer.gtk.linux.x86_64.zip -d /home/ubuntu/installer_`date +%Y%m%d`
	cd /home/ubuntu/installer_`date +%Y%m%d`/idempiere.gtk.linux.x86_64/idempiere-server/

#not indented because of file input
sh console-setup.sh <<!













2
$PIP




$DBPASS
mail.dummy.com




!
cd utils; sh RUN_ImportIdempiere.sh <<!

!
#end of file input

fi #end if $IS_INSTALL_ID == "Y"

# Run iDempiere
if [[ $IS_LAUNCH_ID == "Y" ]]
then
	echo "launching iDempiere with nohup"
	cd /home/ubuntu/installer_`date +%Y%m%d`/idempiere.gtk.linux.x86_64/idempiere-server/; nohup ./idempiere-server.sh &
fi

# TODO: Need section for S3 backup
# Consider modifying the existing backup script
# to issue the s3cmd command to push the newly
# create file the desired s3 bucket
