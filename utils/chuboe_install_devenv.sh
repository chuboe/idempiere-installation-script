#!/bin/bash

# Release Details
#{{{
	# Author
		# Chris Greene
		# Chris@chuboe.com
		#http://ChuckBoecking.com
#}}}

SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")

source $SCRIPTPATH/chuboe.properties
source $SCRIPTPATH/chuboe.properties.logilite-7.1

OSUSER=$(id -u -n)
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


echo "HERE:Install maven"
sudo apt-get update
sudo apt-get install -y maven
sudo systemctl disable idempiere

mkdir $OSUSER_HOME/dev
mkdir $OSUSER_HOME/dev/downloads
mkdir $OSUSER_HOME/dev/plugins

$SCRIPTPATH/utils/downloadtestgz.sh $CHUBOE_PROP_ECLIPSE_SOURCE_HOSTPATH $CHUBOE_PROP_ECLIPSE_SOURCE_FILENAME $OSUSER_HOME/dev/downloads || exit 1
tar -zxvf $OSUSER_HOME/dev/downloads/$CHUBOE_PROP_ECLIPSE_SOURCE_FILENAME -C $OSUSER_HOME/dev/

cd $OSUSER_HOME/dev
git clone -b $CHUBOE_PROP_JENKINS_REPO_BRANCH $CHUBOE_PROP_JENKINS_REPO_URL
git clone -b $CHUBOE_PROP_JENKINS_REPO_BRANCH idempiere myexperiment

cd myexperiment
mvn verify -U

echo "Instructions for building iDempiere in Eclipse:" #{{{
	echo "Open Eclipse and set ~/dev/myexperiment/ as default working directory"
	echo "File>Import select Existing Maven Projects, click browse, select folder, select all, finish"
	echo "File>Import select Existing Projects into Workspace, click browse, navigate to org.idempiere.p2.targetplatform and select folder, finish "
	echo "navigate to the target platform in the project browser, and load target platform"
	echo "close the target platform window, and run debug installation.setup, then server.product"
