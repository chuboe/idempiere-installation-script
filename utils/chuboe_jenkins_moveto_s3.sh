#!/bin/bash

#The purpose of this script is to move files from jenkins to AWS S3.
#The script keeps the S3 file path/name scheme the same so that you do not need to update the script to use S3.
#Execute this script from your jenkins server.
#Note: this script assumes you have already created your S3 Bucket and updated the varialble below.

IDEMPIERE_VERSION="5.1"
IDEMPIERE_RELEASE="20180126"
JENKINS_JOB="iDempiere${IDEMPIERE_VERSION}Rel${IDEMPIERE_RELEASE}"
WORKSPACE="/var/lib/jenkins/workspace/${JENKINS_JOB}/"

#set current build here...
NEXT_BUILD_NUMBER=$(< /var/lib/jenkins/jobs/${JENKINS_JOB}/nextBuildNumber)
BUILD_NUMBER=$(($NEXT_BUILD_NUMBER - 1))

SOURCE_URL="http://localhost/job/${JENKINS_JOB}/"
S3_BUCKET="chuboe-jenkins"
TEMP_DIR_BASE="/tmp/${S3_BUCKET}/"
TEMP_DIR="${TEMP_DIR_BASE}/job/${JENKINS_JOB}/"

#Remove older folders
sudo rm -r ${TEMP_DIR}
#Create new folder
mkdir -p ${TEMP_DIR}

#P2
P2_FILE="site.p2.zip"
P2_URL="/ws/buckminster.output/org.adempiere.server_${IDEMPIERE_VERSION}.0-eclipse.feature/site.p2/*zip*/"
TEMP_P2_DIR="${TEMP_DIR}/${P2_URL}/" 
mkdir -p $TEMP_P2_DIR
wget -q ${SOURCE_URL}/${P2_URL}/${P2_FILE} -O ${TEMP_P2_DIR}/${P2_FILE}
cd ${TEMP_P2_DIR}
md5sum ${P2_FILE} > ${P2_FILE}.md5
#create md5 here

#idempiereServer.gtk.linux.x86_64.zip
SERVER_FILE="idempiereServer.gtk.linux.x86_64.zip"
SERVER_URL="/ws/buckminster.output/org.adempiere.server_${IDEMPIERE_VERSION}.0-eclipse.feature/"
TEMP_SERVER_DIR="${TEMP_DIR}/${SERVER_URL}/"
#no need to make dir because already exists
wget -q ${SOURCE_URL}/${SERVER_URL}/${SERVER_FILE} -O ${TEMP_SERVER_DIR}/${SERVER_FILE}
cd ${TEMP_SERVER_DIR}
md5sum ${SERVER_FILE} > ${SERVER_FILE}.md5

#create md5 here

#Changes - create my own with repo detail
CHANGES_URL="/changes"
cd ${WORKSPACE}; hg summary > ${TEMP_DIR}${CHANGES_URL}

#Migration
MIGRATION_FILE="migration.zip"
MIGRATION_URL="/ws/migration/*zip*/"
TEMP_MIGRATION_DIR="${TEMP_DIR}/${MIGRATION_URL}/"
mkdir -p ${TEMP_MIGRATION_DIR}
wget -q ${SOURCE_URL}/${MIGRATION_URL}/${MIGRATION_FILE} -O ${TEMP_MIGRATION_DIR}/${MIGRATION_FILE}
cd ${TEMP_MIGRATION_DIR}
md5sum ${MIGRATION_FILE} > ${MIGRATION_FILE}.md5

#Create a build version directory
cd ${TEMP_DIR}
mkdir ${BUILD_NUMBER}
mv * ./${BUILD_NUMBER}/
cd ${BUILD_NUMBER}
cp -r * ../.

s3cmd sync -P ${TEMP_DIR_BASE} s3://${S3_BUCKET}/
#Use "-J https://s3.amazonaws.com/chuboe-jenkins" (as example where chuboe-jenkins is the S3_BUCKET) in the installation scrip to install from S3 instead of jenkins.
