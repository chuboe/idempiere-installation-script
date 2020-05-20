#!/bin/bash

#The purpose of this script is to help you create a foreign data wrapper (FDW)
#connection to another postgresql server. Here are the details:
    #always test execution on a test server first (not production)
    #this script assumes the remote server is running iDempiere (not required)
        #could also be a webstore running on mysql
    #Assumes you created the following view on the remote server:
        #create view chuboe_ordertest_v as select o.documentno from c_order o;
    #See 'changeme' below for variables that you should change for your environment.

#create remote server
remote_server_ip='172.30.1.202' #changeme
remote_server_name='remote1'
remote_server_port='5432'
remote_server_db='idempiere'
remote_schema_name='adempiere'

#create user mapping
remote_user_name='adempiere'
remote_user_password='Silly' #changeme

#create foreign table - you will create as many table refs as you wish
#this is just one example.
#the materialized view (_mv) is optional
local_table_reference='chuboe_ordertest_remote_v'
local_table_reference_mv='chuboe_ordertest_remote_mv' #materialized view optional
remote_table_name='chuboe_ordertest_v'

#create fdw
psql -d idempiere -U adempiere -c "CREATE EXTENSION postgres_fdw"

#create reference to remote server in local system
psql -d idempiere -U adempiere -c "CREATE SERVER $remote_server_name
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host '$remote_server_ip', port '$remote_server_port', dbname '$remote_server_db')"

#map our local adempiere user to the remote adempiere user - Note: you should create a new remote user with limited power (not adempeire)
psql -d idempiere -U adempiere -c "CREATE USER MAPPING FOR $remote_user_name
        SERVER $remote_server_name
        OPTIONS (user '$remote_user_name', password '$remote_user_password')"

#create a local reference to a remote table
psql -d idempiere -U adempiere -c "CREATE FOREIGN TABLE $local_table_reference (
documentno character varying(30))
        SERVER $remote_server_name
        OPTIONS (schema_name '$remote_schema_name', table_name '$remote_table_name')"

echo
echo @@@***@@@
echo Test connectivity using the following command:
echo psql -d idempiere -U adempiere -c \"select \* from $local_table_reference\"
echo @@@***@@@
echo

#optionally create a materialized view (local cache) so that you can read
#from the table even when the connection between the servers is down.
psql -d idempiere -U adempiere -c "create materialized view $local_table_reference_mv as select * from $local_table_reference"

echo
echo @@@***@@@
echo "Test local cached copy (materialized view) using the following command:"
echo psql -d idempiere -U adempiere -c \"select \* from $local_table_reference_mv\"
echo
echo Note: you can shut the remote server down and still query this data.
echo @@@***@@@
echo

echo
echo @@@***@@@
echo To remove all above artifacts:
echo psql -d idempiere -U adempiere -c \"drop server $remote_server_name CASCADE\"
echo @@@***@@@
echo

