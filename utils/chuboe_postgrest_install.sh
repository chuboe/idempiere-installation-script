#!/bin/bash

# seach on 'changeme' below to know what to update before you execute this script.

# assumes you have already installed idempiere
## postgresql already exists
## idempiere db already exists
## ~/.pgpass already exists


# Download postgREST
cd /usr/local/bin/
# current version: https://github.com/PostgREST/postgrest/releases/latest
CURRENT_VERSION="v9.0.1"
sudo wget https://github.com/PostgREST/postgrest/releases/download/v9.0.1/postgrest-$CURRENT_VERSION-linux-static-x64.tar.xz
sudo tar xJf postgrest-v9.0.1-linux-static-x64.tar.xz

# changeme: change password
# changeme if needed: localhost (if located on a different server than the idempiere app server)
psql -h localhost -U adempiere -d idempiere -c "create role postrest_web_anon nologin"
psql -h localhost -U adempiere -d idempiere -c "grant usage on schema adempiere to postrest_web_anon"
psql -h localhost -U adempiere -d idempiere -c "grant select on adempiere.c_paymentterm to postrest_web_anon"

psql -h localhost -U adempiere -d idempiere -c "create role postrest_auth noinherit login password 'changememememe'"
psql -h localhost -U adempiere -d idempiere -c "grant postrest_web_anon to postrest_auth"

# changeme: change password from changememememe
echo 'db-uri = "postgres://postrest_auth:changememememe@localhost:5432/idempiere"' | sudo tee -a idempiere-rest.conf
echo 'db-schemas = "adempiere"' | sudo tee -a idempiere-rest.conf
echo 'db-anon-role = "postrest_web_anon"' | sudo tee -a idempiere-rest.conf

# run in a tmux session or by appending " &" to the end of the below command
# ./postgrest idempiere-rest.con

# perform a test using curl
# changeme: set your url as is needed from localhost
# curl http://localhost:3000/c_paymentterm

# How to import json data into excel
# https://raw-labs.com/blog/retrieving-json-data-from-a-rest-api-in-excel-with-power-query/
