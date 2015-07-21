#!/bin/bash

#bring chuboe.properties into context
source chuboe.properties

OSUSER=${1:-$CHUBOE_PROP_IDEMPIERE_OS_USER}


echo -------------------------------------
echo Unjar seed file
echo -------------------------------------
cd $CHUBOE_PROP_IDEMPIERE_PATH/data/seed
sudo -u $OSUSER jar -xvf Adempiere_pg.jar

# remove 'create schema' commands
sudo -u $OSUSER sed -i "/CREATE SCHEMA adempiere;/d" Adempiere_pg.dmp
sudo -u $OSUSER sed -i "/ALTER SCHEMA adempiere OWNER TO adempiere;/d" Adempiere_pg.dmp

# set search_path (schema) 
sudo -u $OSUSER sed -i "s/SET search_path = adempiere, pg_catalog;/SET search_path = $CHUBOE_PROP_DB_SCHEMA, pg_catalog;/" Adempiere_pg.dmp

# rename schema
sudo -u $OSUSER sed -i "s/adempiere\./$CHUBOE_PROP_DB_SCHEMA\./" Adempiere_pg.dmp

# rename role
sudo -u $OSUSER sed -i "s/OWNER TO adempiere/OWNER TO $CHUBOE_PROP_DB_USERNAME/" Adempiere_pg.dmp

echo -------------------------------------
echo Create user and database
echo -------------------------------------

#SQL statements
CHUBOE_SQL_CREATE_ROLE_SU="CREATE ROLE $CHUBOE_PROP_DB_USERNAME LOGIN PASSWORD '$CHUBOE_PROP_DB_PASSWORD'"
CHUBOE_SQL_ALTER_ROLE_SU="ALTER ROLE $CHUBOE_PROP_DB_USERNAME WITH SUPERUSER"
CHUBOE_SQL_ALTER_ROLE_SU_RDS="GRANT RDS_SUPERUSER to $CHUBOE_PROP_DB_USERNAME"
CHUBOE_SQL_CREATE_DB="CREATE DATABASE $CHUBOE_PROP_DB_NAME WITH ENCODING='UNICODE'"
CHUBOE_SQL_GRANT_MASTER="GRANT $CHUBOE_PROP_DB_USERNAME TO $CHUBOE_PROP_DB_USERNAME_SU"
CHUBOE_SQL_CREATE_SCHEMA="CREATE SCHEMA IF NOT EXISTS $CHUBOE_PROP_DB_SCHEMA AUTHORIZATION $CHUBOE_PROP_DB_USERNAME"
CHUBOE_SQL_CREATE_EXTENSION_UUID="CREATE EXTENSION \"uuid-ossp\""


echo ""
echo HERE: You can safely ignore the RDS_SUPERUSER error if you are not using AWS RDS.
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_CREATE_ROLE_SU"
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_ALTER_ROLE_SU"
echo The following line is for AWS RDS. You can ignore if you are not using RDS.
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_ALTER_ROLE_SU_RDS"
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_CREATE_DB"
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_GRANT_MASTER"
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -c "$CHUBOE_SQL_CREATE_SCHEMA"
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -c "$CHUBOE_SQL_CREATE_EXTENSION_UUID"
psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -f Adempiere_pg.dmp

