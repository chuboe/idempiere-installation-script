#!/bin/bash
# Version 1 Chuck Boecking - created

source chuboe.properties

# check to see if test server - else exit
if [[ $CHUBOE_PROP_IS_TEST_ENV != "Y" ]]; then
    echo "Not a test environment - exiting now!"
    echo "Check chuboe.properties => CHUBOE_PROP_IS_TEST_ENV variable."
    exit 1
fi

# update SQL in restored database that might be specific to this server

# update system logos - you can also set them to something else like 'http://cdn6.bigcommerce.com/s-d8bzk61/images/stencil/200x100/products/1988/2724/safetyglassesusa_2267_30575914__24175.1448998397.jpg'
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update AD_SysConfig set isactive = 'N' where upper(name) like 'ZK_LOGO%' or upper(name) like 'ZK_BROWSER_ICON%'"

# backup email to delme table
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "create table delme_client_backup as select * from ad_client"

# SQL to restore email settings if needed for testing
# update ad_client set smtphost = b.smtphost, issmtpauthorization = b.issmtpauthorization, issecuresmtp = b.issecuresmtp, smtpport = b.smtpport , requestuser = b.requestuser, requestemail = b.requestemail from delme_client_backup b where ad_client.ad_client_id = b.ad_client_id;

# disable email in test/sandbox system
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update ad_client set smtphost = '', issmtpauthorization = 'N', issecuresmtp = 'N', smtpport = null, requestuser = '', requestemail = ''"

# Prepend the browser tab with "TEST"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update AD_SysConfig set value = '$CHUBOE_PROP_TEST_ENV_PREFIX'||value||'$CHUBOE_PROP_TEST_ENV_SUFFIX' where upper(name) = 'ZK_BROWSER_TITLE'"

# If you wish to delete all entries in DMS as part of the restore:
#delete from DMS_Association
#delete from dms_version
#delete from DMS_Content
