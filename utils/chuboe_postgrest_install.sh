#!/bin/bash

# seach on 'changeme' below to know what to update before you execute this script.
# See for example: https://github.com/chuboe/idempiere-installation-script/tree/master/apps/PostgrestTimesheet

# assumes you have already installed idempiere
## postgresql already exists
## idempiere db already exists
## ~/.pgpass already exists


# Download postgREST
cd /usr/local/bin/
# current version: https://github.com/PostgREST/postgrest/releases/latest
CURRENT_VERSION="v12.2.0"
PASSWORD_PR="changememememe"
PASSWORD_PRQ="'$PASSWORD_PR'"
sudo wget https://github.com/PostgREST/postgrest/releases/download/$CURRENT_VERSION/postgrest-$CURRENT_VERSION-linux-static-x64.tar.xz
sudo tar xJf postgrest-$CURRENT_VERSION-linux-static-x64.tar.xz

# changeme: change password
# changeme if needed: localhost (if located on a different server than the idempiere app server)
psql -h localhost -U adempiere -d idempiere -c "create schema api"
psql -h localhost -U adempiere -d idempiere -c "create role postrest_web_anon nologin"
psql -h localhost -U adempiere -d idempiere -c "create table adempiere.chuboe_todo (id uuid primary key default uuid_generate_v4(), done boolean not null default false, task text not null, due timestamptz)"
psql -h localhost -U adempiere -d idempiere -c "insert into adempiere.chuboe_todo (task) values ('read first todo')"
psql -h localhost -U adempiere -d idempiere -c "create view api.todo as select * from adempiere.chuboe_todo"
psql -h localhost -U adempiere -d idempiere -c "grant usage on schema api to postrest_web_anon"
psql -h localhost -U adempiere -d idempiere -c "grant all on api.todo to postrest_web_anon" #note: this includes insert, update and delete
psql -h localhost -U adempiere -d idempiere -c "create role postrest_auth noinherit login password $PASSWORD_PRQ"
psql -h localhost -U adempiere -d idempiere -c "grant postrest_web_anon to postrest_auth"

# changeme: change password from changememememe
echo 'db-uri = "postgres://postrest_auth:'$PASSWORD_PR'@localhost:5432/idempiere"' | sudo tee idempiere-rest.conf
echo 'db-schemas = "api"' | sudo tee -a idempiere-rest.conf
echo 'db-anon-role = "postrest_web_anon"' | sudo tee -a idempiere-rest.conf

# update ~/.pgpass for convenience
echo "*:*:*:postrest_auth:$PASSWORD_PR" | tee -a ~/.pgpass
chmod 600 ~/.pgpass

echo ''
echo '** instructions to role use with psqli **'
echo 'log in via psql using postgrest_auth'
echo '    psql -U postrest_auth -d idempiere'
echo 'then, use "set role postrest_web_anon" to allow postgrest_auth to interact with tables'
echo '    set role postrest_web_anon;'
echo 'then, use set serach_path to prevent needing to use the api. prefix.'
echo '    set search_path = api;'

echo ''
echo '**Hints**'
echo 'For quick run and test: /usr/local/bin/postgrest /usr/local/bin/idempiere-rest.conf'
echo '    Use ctrl+c to kill process - see comments for how to install as service'
echo 'For details how to run as service, see comments in script.'
echo ''
echo 'First read: curl http://localhost:3000/todo'
echo 'First insert: see comments - issues with single and double quotes with echo'
      # curl http://localhost:3000/todo -X POST -H "Content-Type: application/json" -d '{"task": "do great things"}'
echo 'First update: see comments - copy your uuid from above read and update accordingly'
      # curl http://localhost:3000/todo?id=eq.3abdcd60-be25-4091-a75c-55ddd2e883bb -X PATCH -H "Content-Type: application/json" -d '{"task": "do more great things"}'

echo ''
echo '**Read the end the file for more detailed instructions**'

# Notes:
#   By using uuid, you do not need to give permissions to sequences
#   If you do need to give permissions to sequences: grant usage, select ON ALL SEQUENCES IN SCHEMA adempiere TO postrest_web_anon;

# install and run service
# run in a tmux session or by appending " &" to the end of the below command
#     /usr/local/bin/postgrest /usr/local/bin/idempiere-rest.conf
# To install as service, copy this file with sudo to /etc/systemd/system/postgrest.service
#    https://github.com/chuboe/idempiere-installation-script/blob/master/service/postgrest.service
# Issue the follow commands:
#    cd /etc/systemd/system/
#    sudo wget https://raw.githubusercontent.com/chuboe/idempiere-installation-script/master/service/postgrest.service
#    sudo systemctl daemon-reload
#    sudo systemctl start postgrest
#    sudo systemctl enable postgrest
#    sudo systemctl status postgrest # confirm service started

# How to import json data into excel
# https://raw-labs.com/blog/retrieving-json-data-from-a-rest-api-in-excel-with-power-query/

# https://supabase.com/docs/guides/api/quickstart?database-method=sql
# -- Turn on security
# alter table adempiere.chuboe_todo
# enable row level security;
# -- Allow anonymous access
# create policy "Allow anonymous access"
#   on adempiere.chuboe_todo
#   for select
#   to postrest_web_anon
#   using (true);

# If you wish to remove:
# Issue the followng statements using psql as adempiere
#    revoke select ON todo from postrest_web_anon;
#    revoke usage on schema api from postrest_web_anon;
#    drop role postrest_web_anon;
#    drop role postrest_auth;
# Stop postgrest
# Issue the following command;
#    sudo rm /usr/local/bin/postgrest

# https://postgrest.org/en/v11.2/tutorials/tut0.html
# if you wish to create a simple table to test writing data, issue the following statements as adempiere:
#     create table todos (id serial primary key, done boolean not null default false, task text not null, due timestamptz);
#     grant select on todos to postrest_web_anon;
#     grant insert on todos to postrest_web_anon;
#     grant update on todos to postrest_web_anon;
#     insert into todos (task) values ('finish tutorial 0'), ('pat self on back');
# if you wish to grant select on all sequences so that you do not need to individually assign:
#     grant usage, select ON ALL SEQUENCES IN SCHEMA adempiere TO postrest_web_anon;
# you can test reading and writing to this table with postgrest_auth with the above psql commands.
# to post/insert a new record via the api to this table:
#    curl http://localhost:3000/todos -X POST -H "Content-Type: application/json" -d '{"task": "do great things"}'
# to read the results:
#    curl http://localhost:3000/todos
# to update the record (note - assumes above record created with id=1):
#    curl "http://localhost:3000/todos?id=eq.1" -X PATCH -H "Content-Type: application/json" -d '{"task": "do more great things"}'

# Below is a summary view that you can use to demonstrate api access at a higher level
# At the bottom, there exists a grant statement that makes the view available to postegrest
# example call: curl http://localhost:3000/business_partner
#create or replace view business_partner as
#with last_payment as (
#    select
#    max(p.c_payment_id) as c_payment_id,
#    p.c_bpartner_id
#    from c_payment p
#    where p.docstatus = 'CO'
#    group by c_bpartner_id
#),
#primary_address as (
#    select
#    max(bpl.c_bpartner_location_id) as c_bpartner_location_id,
#    bpl.c_bpartner_id
#    from c_bpartner_location bpl
#    where bpl.isactive='Y'
#    group by bpl.c_bpartner_id
#),
#primary_contact as (
#    select
#    max(u.ad_user_id) as ad_user_id,
#    u.c_bpartner_id
#    from ad_user u
#    where u.isactive='Y'
#    group by u.c_bpartner_id
#)
#select
#bp.name,
#bp.value as search_key,
#bp.totalopenbalance,
#bp.iscustomer,
#bp.isvendor,
#coalesce(p.payamt,0) as payment_amount_last,
#p.dateacct as payment_date_last,
#coalesce(l.address1,'') as address1,
#coalesce(l.address2,'') as address2,
#coalesce(l.city,'') as city,
#coalesce(l.regionname,r.name,'') as state,
#coalesce(l.postal,'') as zip,
#coalesce(u.name,'') as contact_name,
#coalesce(u.email,'') as contact_email,
#coalesce(u.phone,'') as contact_phone
#from c_bpartner bp
#left join last_payment lp on bp.c_bpartner_id = lp.c_bpartner_id
#left join c_payment p on lp.c_payment_id = p.c_payment_id
#left join primary_address pa on bp.c_bpartner_id = pa.c_bpartner_id
#left join c_bpartner_location bpl on pa.c_bpartner_location_id = bpl.c_bpartner_location_id
#left join c_location l on bpl.c_location_id = l.c_location_id
#left join c_region r on l.c_region_id = r.c_region_id
#left join primary_contact pc on bp.c_bpartner_id = pc.c_bpartner_id
#left join ad_user u on pc.ad_user_id = u.ad_user_id
#where bp.isactive = 'Y'
#and lower(bp.name) not like '%store%'
#and lower(bp.name) not like '%standard%'
#and lower(bp.name) not like '%color%'
#and lower(bp.name) not like '%chrome%'
#and lower(bp.name) not like '%garden%'
#;
#grant select on adempiere.business_partner to postrest_web_anon;

