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
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update AD_SysConfig set isactive = 'N' where upper(name) like 'ZK_LOGO%'"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update AD_SysConfig set value = 'default' where upper(name) like 'ZK_THEME'"
# update search sources to test...
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update Chuboe_Search_Source set chuboe_search_url = replace(chuboe_search_url,'http://orangetsunami.com','http://test.orangetsunami.com')"
# disable email in test/sandbox system
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update ad_client set smtphost = '', issmtpauthorization = 'N', issecuresmtp = 'N', smtpport = null, requestuser = '', requestemail = ''"
# Prepend the browser tab with "TEST"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -d idempiere -U adempiere -c "update AD_SysConfig set value = 'T_'||value where upper(name) = 'ZK_BROWSER_TITLE'"
