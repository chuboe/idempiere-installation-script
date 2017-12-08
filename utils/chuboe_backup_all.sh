#!/bin/bash
# Version 1 Chuck Boecking - created

# This script belongs to a collection of scripts that copies iD to a new instance.
# This script creates the backup.
# This differs from chuboe_backup_s3cmd.sh because it also move binaries.
# This script series assumes that the chuboe installation script was used to install iD on both servers
# Be aware that you need about 10GB of free space on the drive for the below to succeed.

source chuboe.properties
TMP_BACKUP_FILE_NAME=id.tar.gz
TMP_BACKUP_PATH=/tmp/id_back/
TMP_BACKUP_PATH_DIR=$TMP_BACKUP_PATH/dirs/

# remove previous backups
echo "HERE: remove previous backups"
sudo rm -r $TMP_BACKUP_PATH

# create a backup of iDempiere's binaries to establish a known backup point
echo "HERE: create backup of id binaries"
cd $CHUBOE_PROP_UTIL_HG_UTIL_PATH
./chuboe_hg_bindir.sh

# create a database backup that can be used later
echo "HERE: create backup of db"
cd $CHUBOE_PROP_IDEMPIERE_PATH/utils/
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER ./RUN_DBExport.sh

# create temp backup directory and copy all files
echo "HERE: cp iD directory to temp folder"
sudo mkdir -p $TMP_BACKUP_PATH_DIR
sudo chown $CHUBOE_PROP_IDEMPIERE_OS_USER:$CHUBOE_PROP_IDEMPIERE_OS_USERGROUP $TMP_BACKUP_PATH -R
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER cp $CHUBOE_PROP_IDEMPIERE_PATH $TMP_BACKUP_PATH_DIR -R

# uncomment below cp statements to move DMS folders if present
# sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER cp /opt/DMS_Content/ $TMP_BACKUP_PATH_DIR -R
# sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER cp /opt/DMS_Thumbnails/ $TMP_BACKUP_PATH_DIR -R

# create tar backup
echo "HERE: create tar file"
cd $TMP_BACKUP_PATH
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER tar cvfz $TMP_BACKUP_FILE_NAME dirs/

# keep the tar file but delete the directory to preserve space
sudo rm -r $TMP_BACKUP_PATH_DIR