#!/bin/bash

#bring chuboe.properties into context
source chuboe.properties

CURR_DIR=$(pwd)

OSUSER=${1:-$CHUBOE_PROP_IDEMPIERE_OS_USER}

echo HERE:OSUSER=$OSUSER

echo -------------------------------------
echo Unjar seed file as $OSUSER HERE:
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

# set permissions back to iDempiere user if needed
if [[ $OSUSER == "root" ]]
then
	sudo chown $CHUBOE_PROP_IDEMPIERE_OS_USER:$CHUBOE_PROP_IDEMPIERE_OS_USER Adempiere_pg.dmp
fi

echo -------------------------------------
echo Create user and database
echo -------------------------------------

#SQL statements
CHUBOE_SQL_CREATE_ROLE_SU="CREATE ROLE $CHUBOE_PROP_DB_USERNAME LOGIN PASSWORD '$CHUBOE_PROP_DB_PASSWORD'"
CHUBOE_SQL_ALTER_ROLE_SU="ALTER ROLE $CHUBOE_PROP_DB_USERNAME WITH SUPERUSER"
CHUBOE_SQL_ALTER_ROLE_SU_RDS="GRANT RDS_SUPERUSER to $CHUBOE_PROP_DB_USERNAME"
CHUBOE_SQL_GRANT_MASTER="GRANT $CHUBOE_PROP_DB_USERNAME TO $CHUBOE_PROP_DB_USERNAME_SU"
CHUBOE_SQL_CREATE_DB="CREATE DATABASE $CHUBOE_PROP_DB_NAME WITH ENCODING='UNICODE' OWNER $CHUBOE_PROP_DB_USERNAME"
CHUBOE_SQL_CREATE_SCHEMA="CREATE SCHEMA IF NOT EXISTS $CHUBOE_PROP_DB_SCHEMA AUTHORIZATION $CHUBOE_PROP_DB_USERNAME"
CHUBOE_SQL_CREATE_EXTENSION_UUID="CREATE EXTENSION \"uuid-ossp\""
CHUBOE_SQL_SET_SEARCH_PATH="ALTER ROLE $CHUBOE_PROP_DB_USERNAME SET search_path TO $CHUBOE_PROP_DB_SCHEMA"

echo ""
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_CREATE_ROLE_SU"
echo HERE: The following line will fail on AWS RDS. You can ignore if you are using RDS.
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_ALTER_ROLE_SU"
echo HERE: The following line is for AWS RDS. You can ignore if you are not using RDS.
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_ALTER_ROLE_SU_RDS"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_GRANT_MASTER"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME_SU -c "$CHUBOE_SQL_CREATE_DB"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -c "$CHUBOE_SQL_CREATE_SCHEMA"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -c "$CHUBOE_SQL_CREATE_EXTENSION_UUID"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -c "$CHUBOE_SQL_SET_SEARCH_PATH"
sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -f Adempiere_pg.dmp

#temporarily needed
#cd $CURR_DIR
#sudo -u $CHUBOE_PROP_IDEMPIERE_OS_USER psql -h $CHUBOE_PROP_DB_HOST -p $CHUBOE_PROP_DB_PORT -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -f chuboe_restore_version_mismatch_function.sql
