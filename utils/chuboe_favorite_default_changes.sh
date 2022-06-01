#!/bin/bash
# Version 1 Chuck Boecking - created

source chuboe.properties

# check to see if test server - else exit
if [[ $CHUBOE_PROP_IS_TEST_ENV != "Y" ]]; then
    echo "Not a test environment - exiting now!"
    echo "Check chuboe.properties => CHUBOE_PROP_IS_TEST_ENV variable."
    exit 1
fi

sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -f chuboe_favorite_default_changes.sql

sudo mkdir -p /opt/idempiere-attach/
sudo mkdir -p /opt/idempiere-archive/
sudo mkdir -p /opt/idempiere-image/
sudo mkdir -p /opt/DMS_Content/
sudo mkdir -p /opt/DMS_Thumbnails/
sudo chown -R idempiere:idempiere /opt/idempiere*
sudo chown -R idempiere:idempiere /opt/DMS*
