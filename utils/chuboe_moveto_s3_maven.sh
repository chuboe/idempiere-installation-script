#!/bin/bash

#The purpose of this script is to move files from Maven to AWS S3.
#The script keeps the S3 file path/name scheme the same so that you do not need to update the script to use S3.
#Execute this script from your jenkins server.
#Note: this script assumes you have already created your S3 Bucket and updated the varialbles below.

source chuboe.properties

WORKSPACE="$1/" 
echo "WORKSPACE = $WORKSPACE"
if [ "$WORKSPACE" = "/" ] 
then
	echo "need workspace argument"
	exit 1
fi

#set current build here...
BUILD_NUMBER=`date +"%Y%m%d%H%M%S"`

S3_BUCKET="technologicsellswordmaventos3"
OSUSER=$(id -u -n)
TEMP_DIR_BASE="/tmp/${OSUSER}/${S3_BUCKET}/"
TEMP_DIR="${TEMP_DIR_BASE}/job/${CHUBOE_PROP_JENKINS_PROJECT}/ws/"

#Remove older folders
rm -r ${TEMP_DIR}
#Create new folder
mkdir -p ${TEMP_DIR}

#P2
P2_FILE="repository"
P2_PATH="org.idempiere.p2/target/"
P2_DIR="repository/"
TEMP_P2_DIR="${TEMP_DIR}/${P2_PATH}/${P2_DIR}*zip*/" 
mkdir -p $TEMP_P2_DIR
cd ${WORKSPACE}${P2_PATH}
zip ${TEMP_P2_DIR}${P2_FILE} ${P2_DIR} -r
cd ${TEMP_P2_DIR}
md5sum ${P2_FILE}.zip > ${P2_FILE}.zip.md5

#idempiereServer.gtk.linux.x86_64.zip
SERVER_FILE="idempiereServer${CHUBOE_PROP_IDEMPIERE_VERSION}Daily.gtk.linux.x86_64"
TARGET_FILE="idempiere.gtk.linux.x86_64"
SERVER_URL="org.idempiere.p2/target/products/org.adempiere.server.product/"
SERVER_DIR="linux/gtk/x86_64/"
TEMP_SERVER_DIR="${TEMP_DIR}/${SERVER_URL}/"
DELME_PATH="/tmp/${OSUSER}/iDempiereServerDELME/"
DELME_DIR="${TARGET_FILE}/idempiere-server"
mkdir -p ${DELME_PATH}${DELME_DIR}
cp -r ${WORKSPACE}${SERVER_URL}${SERVER_DIR}/* ${DELME_PATH}${DELME_DIR}
mkdir -p ${TEMP_SERVER_DIR}
cd ${DELME_PATH}
zip ${TEMP_SERVER_DIR}${SERVER_FILE}.zip ${DELME_DIR}/* -r
rm -r ${DELME_PATH}
cd ${TEMP_SERVER_DIR}
md5sum ${SERVER_FILE}.zip > ${SERVER_FILE}.zip.md5

#Changes - create my own with repo detail
CHANGES_URL="/changes"
cd ${WORKSPACE}; hg summary > ${TEMP_DIR}${CHANGES_URL}

#Migration
MIGRATION_FILE="migration"
MIGRATION_URL="migration/*zip*/"
TEMP_MIGRATION_DIR="${TEMP_DIR}/${MIGRATION_URL}/"
mkdir -p ${TEMP_MIGRATION_DIR}
cd ${WORKSPACE}${SERVER_URL}${SERVER_DIR}
zip ${TEMP_MIGRATION_DIR}${MIGRATION_FILE} ${MIGRATION_FILE} -r
cd ${TEMP_MIGRATION_DIR}
md5sum ${MIGRATION_FILE}.zip > ${MIGRATION_FILE}.zip.md5

#Create a build version directory
mkdir -p ${TEMP_DIR}${BUILD_NUMBER}
cd ${TEMP_DIR}
mv * ./${BUILD_NUMBER}/
cd ${BUILD_NUMBER}
cp -r * ../.

#cd ${TEMP_DIR}
#cp -r * ${BUILD_NUMBER}

s3cmd sync -P ${TEMP_DIR_BASE} s3://${S3_BUCKET}/
#Use "-J https://s3.amazonaws.com/chuboe-jenkins" (as example where chuboe-jenkins is the S3_BUCKET) in the installation scrip to install from S3 instead of jenkins.

#Remove temp folders
rm -r ${TEMP_DIR}
