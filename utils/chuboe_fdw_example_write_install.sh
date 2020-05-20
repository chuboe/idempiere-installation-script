#!/bin/bash

#The purpose of this script is to help you create a foreign data wrapper (FDW)
#connection to another postgresql server for write purposes.
#Here are the details:
    #always test execution on a test server first (not production)
    #this script assumes the remote server is running iDempiere (not required)
        #could also be a webstore running on mysql
    #See 'changeme' below for variables that you should change for your environment.

#create remote server
remote_server_ip='172.30.1.104' #changeme
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
remote_table_name='i_order'
local_table_reference='i_order_remote'

#order migration tools
local_migrate_seq=chuboe_migrate_order_seq
local_order_batch=chuboe_order_batch

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
    i_order_id numeric(10,0) NOT NULL,
    ad_client_id numeric(10,0),
    ad_org_id numeric(10,0),
    ad_orgtrx_id numeric(10,0),
    isactive character(1) DEFAULT 'Y'::bpchar,
    created timestamp without time zone DEFAULT statement_timestamp() NOT NULL,
    createdby numeric(10,0),
    updated timestamp without time zone DEFAULT statement_timestamp() NOT NULL,
    updatedby numeric(10,0),
    i_isimported character(1) DEFAULT 'N'::bpchar NOT NULL,
    i_errormsg character varying(2000),
    processing character(1),
    processed character(1) DEFAULT 'N'::bpchar,
    salesrep_id numeric(10,0),
    m_warehouse_id numeric(10,0),
    m_pricelist_id numeric(10,0),
    c_currency_id numeric(10,0),
    m_shipper_id numeric(10,0),
    issotrx character(1) DEFAULT 'Y'::bpchar,
    c_bpartner_id numeric(10,0),
    bpartnervalue character varying(40),
    name character varying(60),
    c_bpartner_location_id numeric(10,0),
    billto_id numeric(10,0),
    c_location_id numeric(10,0),
    address1 character varying(60),
    address2 character varying(60),
    postal character varying(10),
    city character varying(60),
    c_region_id numeric(10,0),
    regionname character varying(60),
    c_country_id numeric(10,0),
    countrycode character(2),
    ad_user_id numeric(10,0),
    contactname character varying(60),
    email character varying(60),
    phone character varying(40),
    c_project_id numeric(10,0),
    c_activity_id numeric(10,0),
    c_doctype_id numeric(10,0),
    doctypename character varying(60),
    c_paymentterm_id numeric(10,0),
    paymenttermvalue character varying(40),
    c_order_id numeric(10,0),
    documentno character varying(30),
    dateordered timestamp without time zone,
    dateacct timestamp without time zone,
    description character varying(255),
    m_product_id numeric(10,0),
    productvalue character varying(40),
    upc character varying(30),
    sku character varying(30),
    c_tax_id numeric(10,0),
    taxindicator character varying(10),
    taxamt numeric DEFAULT 0,
    c_orderline_id numeric(10,0),
    linedescription character varying(255),
    c_uom_id numeric(10,0),
    qtyordered numeric DEFAULT 0,
    priceactual numeric DEFAULT 0,
    freightamt numeric DEFAULT 0,
    c_campaign_id numeric(10,0),
    c_charge_id numeric(10,0),
    chargename character varying(60),
    c_ordersource_id numeric(10,0) DEFAULT NULL::numeric,
    c_ordersourcevalue character varying(40) DEFAULT NULL::character varying,
    deliveryrule character(1) DEFAULT NULL::bpchar,
    i_order_uu character varying(36) DEFAULT NULL::character varying,
    CONSTRAINT i_order_isactive_check CHECK ((isactive = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT i_order_issotrx_check CHECK ((issotrx = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT i_order_processed_check CHECK ((processed = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
)
        SERVER $remote_server_name
        OPTIONS (schema_name '$remote_schema_name', table_name '$remote_table_name')"

echo
echo @@@***@@@
echo Test connectivity using the following command:
echo psql -d idempiere -U adempiere -c \"select \* from $local_table_reference limit 1\"
echo @@@***@@@
echo

echo
echo @@@***@@@
echo Test write ability using the following command:
echo psql -d idempiere -U adempiere -c \"insert into $local_table_reference \(i_order_id, ad_client_id, ad_org_id, description\) values \(nextid\(746,\'N\'\),11,11,\'test\'\)\"
echo Note: The above command uses a function that will execute locally \(pulls from wrong db\)
echo Note: You will need to add a trigger to the remote table to have the ID set automatically.
echo @@@***@@@
echo

echo
echo @@@***@@@
echo Create a table to batch orders:
echo psql -d idempiere -U adempiere -c \"create table $local_order_batch as select documentno as chuboe_batchno, c_order_id from c_order limit 0\"
echo @@@***@@@
echo

echo
echo @@@***@@@
echo Create a script to get the next batch number then add all new orders to the batch table:
echo chuboe_batchno=\`date +%Y%m%d%H%M%S\`
echo psql -d idempiere -U adempiere -c \"insert into $local_order_batch select \$chuboe_batchno, o.c_order_id  from c_order o where o.c_order_id not in \(select x.c_order_id from $local_order_batch x\)\"
echo execute the above insert into $local_table_reference select from c_order where c_order_id in $local_order_batch where chuboe_batchno=\$chuboe_batchno
echo Note: by batching orders, you guarantee no order will be missed or duplicated
echo @@@***@@@
echo

echo
echo @@@***@@@
echo To delete all the above artifacts, issue the following:
echo psql -d idempiere -U adempiere -c \"drop SERVER $remote_server_name cascade\"
echo psql -d idempiere -U adempiere -c \"drop table $local_order_batch\"
echo @@@***@@@
echo
