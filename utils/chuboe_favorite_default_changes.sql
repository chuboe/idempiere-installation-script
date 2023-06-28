-- run this script using the following commands:
-- source chuboe.properties
-- psql -U $CHUBOE_PROP_DB_USERNAME -h $CHUBOE_PROP_DB_HOST -d $CHUBOE_PROP_DB_NAME -f chuboe_favorite_default_changes.sql

-- Need to account for the following:
-- Add Created and Updated fields to Table, Column, Window, Tab, Field
-- Need to remember to add Charge as default Accounting Dimension for new customers

-- system config changes
update ad_sysconfig set value = '3' where name = 'START_VALUE_BPLOCATION_NAME';
update ad_sysconfig set value = '5' where name = 'USER_LOCKING_MAX_LOGIN_ATTEMPT';

-- performance indexes
CREATE INDEX IF NOT EXISTS chuboe_fact_acct_doc_idx ON fact_acct USING btree (account_id, ad_table_id, record_id); -- improves BSD
CREATE INDEX IF NOT EXISTS chuboe_fact_acct_sum_pa_idx ON fact_acct_summary USING btree (account_id, ad_org_id, dateacct, pa_reportcube_id); -- improves finReport
CREATE INDEX IF NOT EXISTS chuboe_journalline_hdr_idx ON gl_journalline USING btree (gl_journal_id);
CREATE INDEX IF NOT EXISTS chuboe_requpdate_req_idx ON r_requestupdate USING btree (r_request_id);
create index IF NOT EXISTS chuboe_order_tax_hdr_idx on c_ordertax(c_order_id);
create index IF NOT EXISTS chuboe_invoice_tax_hdr_idx on c_invoicetax(c_invoice_id);
create index IF NOT EXISTS chuboe_allocationline_hdr_idx on c_allocationline_hdr(c_allocationhdr_id);
CREATE INDEX IF NOT EXISTS chuboe_c_invoiceline_inoutline_id ON c_invoiceline USING btree (m_inoutline_id );

--make certain tables high volume to promote a search box when window is opened. 
update ad_table set ishighvolume = 'Y' where ad_table_id in (217); -- doctype

--remove all references to '&' in the menu
update ad_menu set name = replace(name, '&','and') where name like '%&%';

--make all tabs default to grid view.
update ad_tab set issinglerow = 'N'; -- better for teaching new users iDempiere
--TODO make this field default to N for future tabs

--Fields to include in quick edit
update AD_Field set isquickentry = 'Y' where AD_Field_ID in (9614,9623); -- bp customer and vendor checkbox

--make the GL Journal window more intuative for editing in grid view - Accountants love this
update ad_field set seqnogrid = seqnogrid+200 where ad_tab_id = 200008;
update ad_field set seqnogrid = 10 where ad_field_id = 200214; --org
update ad_field set seqnogrid = 20 where ad_field_id = 200216; --line
update ad_field set seqnogrid = 65 where ad_field_id = 200217; --desc
update ad_field set seqnogrid = 40 where ad_field_id = 200223; --account
update ad_field set seqnogrid = 50 where ad_field_id = 200244; --dr
update ad_field set seqnogrid = 60 where ad_field_id = 200245; --cr
update ad_field set seqnogrid = 70 where ad_field_id = 200224; --bp
update ad_field set seqnogrid = 80 where ad_field_id = 200231; --product
update ad_field set seqnogrid = 90 where ad_field_id = 200227; --campaign
update ad_field set seqnogrid = 100 where ad_field_id = 200229; --project
update ad_field set seqnogrid = 110 where ad_field_id = 200228; --sales region
update ad_field set seqnogrid = 120 where ad_field_id = 200226; --activity

-- Bank related changes
update ad_column set istoolbarbutton = 'B' where AD_Column_ID=208442; -- bank statement - create lines from batch - show as button
update ad_field set xposition = 5, name='Create Lines from Batch' where AD_Field_ID=201691;
update AD_Menu set name = 'Bank' where AD_Menu_ID=171; -- remove the word cash
update AD_Menu set name = 'Bank Statement' where AD_Menu_ID= 234; -- remove the word cash
update AD_Menu set name = 'Bank Transfer' where AD_Menu_ID= 53190; -- remove the word cash

-- Update Selection Columns to have a sequence of 99 instead of null or 0. This way all your new columns go to the top of the search list by default.
update ad_column set seqnoselection = 99 where ad_column_id in
(
select ad_column_id from ad_column where isselectioncolumn = 'Y' and (seqnoselection is null or seqnoselection = 0)
);

update ad_column set IsSelectionColumn='Y' where ColumnName in ('M_Product_Id','C_Charge_ID','C_BPartner_ID');

-- Default Window, Tab and Field => Tab subtab => Create fields process => From to today's date since this is the most common scenario
update AD_Process_Para set DefaultValue = '@#Date@' where AD_Process_Para_ID=200077;

-- Default Table and Column => Column subtab => Synchronize Columns process => Date From parameter to today's date since this is the most common scenario
update AD_Process_Para set DefaultValue = '@#Date@' where AD_Process_Para_ID=200381;

-- Payments into Batch window, do not allow the bank account field to be edited after save
update AD_Column
set IsUpdateable='N'
where AD_Column_ID=208412;

-- Track changes on all tables
update ad_table set ischangelog = 'Y'; -- note this field is not respected; however, it does default to the column.
update ad_column set isallowlogging = 'Y';

-- Make change log tracking default on all new tables
update AD_Column set defaultvalue = 'Y' where AD_Column_ID=8564;

-- Make Window, Tab Field => Tab subtab => Single Row Layout default to N
update ad_column set defaultvalue = 'N' where AD_Column_ID=166;

-- Default all records to *
update ad_column set defaultvalue = '0' 
where defaultvalue = '@#AD_Org_ID@'
and ad_table_id not in 
(select ad_table_id from ad_table where lower(tablename) in ('c_order', 'c_invoice', 'gl_journal', 'm_inout', 'm_requisition', 'm_inventory', 'm_movement')
);

-- Make Request Calendar show for all clients
update PA_DashboardContent set ad_client_id = 0 where PA_DashboardContent_ID=50004;

-- make it impossible to create columns from all tables by mistake
update AD_Process_Para set ReadOnlyLogic = '1=1' where AD_Process_Para_ID=631;

-- change windows to set all transaction windows to maintain
update ad_window set WindowType='M' where WindowType='T';

-- default ZK Session Timeout to 3 hours
update AD_SysConfig set value = '10800' where AD_SysConfig_ID=200137;

-- update c_allocationline => link to header to be search instead of table/direct
update AD_Column set AD_Reference_ID=30 where AD_Column_ID=4874;

-- create default storage providers
INSERT INTO AD_StorageProvider (AD_StorageProvider_ID,AD_Client_ID,AD_Org_ID,Created,CreatedBy,Updated,UpdatedBy,IsActive,Name,Method,Folder,AD_StorageProvider_UU) VALUES (nextid(200033, 'N'),0,0,TO_TIMESTAMP('2022-05-31 21:34:28','YYYY-MM-DD HH24:MI:SS'),100,TO_TIMESTAMP('2022-05-31 21:34:28','YYYY-MM-DD HH24:MI:SS'),100,'Y','id-attachment','FileSystem','/opt/idempiere-attachment','e1207f03-ae9f-4a7b-832c-3943f195378d');
INSERT INTO AD_StorageProvider (AD_StorageProvider_ID,AD_Client_ID,AD_Org_ID,Created,CreatedBy,Updated,UpdatedBy,IsActive,Name,Method,Folder,AD_StorageProvider_UU) VALUES (nextid(200033, 'N'),0,0,TO_TIMESTAMP('2022-05-31 21:34:39','YYYY-MM-DD HH24:MI:SS'),100,TO_TIMESTAMP('2022-05-31 21:34:39','YYYY-MM-DD HH24:MI:SS'),100,'Y','id-archive','FileSystem','/opt/idempiere-archive','e5dfa924-7e66-45d8-a35a-e393cf6910bc');
INSERT INTO AD_StorageProvider (AD_StorageProvider_ID,AD_Client_ID,AD_Org_ID,Created,CreatedBy,Updated,UpdatedBy,IsActive,Name,Method,Folder,AD_StorageProvider_UU) VALUES (nextid(200033, 'N'),0,0,TO_TIMESTAMP('2022-05-31 21:34:53','YYYY-MM-DD HH24:MI:SS'),100,TO_TIMESTAMP('2022-05-31 21:34:53','YYYY-MM-DD HH24:MI:SS'),100,'Y','id-image','FileSystem','/opt/idempiere-image','4f512366-905f-4fc7-a959-c98508ecbbf0');
INSERT INTO AD_StorageProvider (AD_StorageProvider_ID,AD_Client_ID,AD_Org_ID,Created,CreatedBy,Updated,UpdatedBy,IsActive,Name,Method,Folder,AD_StorageProvider_UU) VALUES (nextid(200033, 'N'),0,0,TO_TIMESTAMP('2022-05-31 21:35:30','YYYY-MM-DD HH24:MI:SS'),100,TO_TIMESTAMP('2022-05-31 21:35:30','YYYY-MM-DD HH24:MI:SS'),100,'Y','dms-content','FileSystem','/opt/DMS_Content','19ab1c28-3cd7-46db-b614-2cd8c8238cc7');
INSERT INTO AD_StorageProvider (AD_StorageProvider_ID,AD_Client_ID,AD_Org_ID,Created,CreatedBy,Updated,UpdatedBy,IsActive,Name,Method,Folder,AD_StorageProvider_UU) VALUES (nextid(200033, 'N'),0,0,TO_TIMESTAMP('2022-05-31 21:35:30','YYYY-MM-DD HH24:MI:SS'),100,TO_TIMESTAMP('2022-05-31 21:35:30','YYYY-MM-DD HH24:MI:SS'),100,'Y','dms-thumbnail','FileSystem','/opt/DMS_Thumbnails','19ab1c28-3cd7-46db-b614-2cd8c8238cc8');

--Info window
update AD_InfoColumn set DefaultValue=null where AD_InfoColumn_ID=200036;
update AD_InfoColumn set DefaultValue=null where AD_InfoColumn_ID=200037;

-- update storage providers
-- you can run this query as many times as is needed as you create clients
update ad_clientinfo
set ad_storageprovider_id = (select x.ad_storageprovider_id from ad_storageprovider x where ad_storageprovider_uu = 'e1207f03-ae9f-4a7b-832c-3943f195378d'),
StorageArchive_ID = (select x.ad_storageprovider_id from ad_storageprovider x where ad_storageprovider_uu = 'e5dfa924-7e66-45d8-a35a-e393cf6910bc'),
StorageImage_ID = (select x.ad_storageprovider_id from ad_storageprovider x where ad_storageprovider_uu = '4f512366-905f-4fc7-a959-c98508ecbbf0')
where ad_client_id <> 0;

-- confirm on close and void
update ad_clientinfo set IsConfirmOnDocClose='Y' where ad_client_id <> 0;
update ad_clientinfo set IsConfirmOnDocVoid='Y' where ad_client_id <> 0;

-- update system
update ad_system set IsAllowStatistics='N', IsAutoErrorReport='N' where AD_System_ID=0;

-- update logos to show pristine
insert into ad_sysconfig
values (
    nextid(50009,'N'),
    0,
    0,
    now(),
    now(),
    100,
    100,
    'Y',
    'ZK_LOGO_LARGE',
    'https://raw.githubusercontent.com/chuboe/idempiere-installation-script/master/web/Login-Do-Not.png',
    '',
    'U',
    'S',
    generate_uuid()
)
;

insert into ad_sysconfig
values (
    nextid(50009,'N'),
    0,
    0,
    now(),
    now(),
    100,
    100,
    'Y',
    'ZK_LOGO_SMALL',
    'https://raw.githubusercontent.com/chuboe/idempiere-installation-script/master/web/Top-Left-Do-Not.png',
    '',
    'U',
    'S',
    generate_uuid()
)
;

insert into ad_sysconfig
values (
    nextid(50009,'N'),
    0,
    0,
    now(),
    now(),
    100,
    100,
    'Y',
    'ZK_BROWSER_ICON',
    'https://raw.githubusercontent.com/chuboe/idempiere-installation-script/master/web/Fav-Do-Not.png',
    '',
    'U',
    'S',
    generate_uuid()
)
;

--update Payment Selection window => Create From button => Payment Rule param field to default to nothing
update AD_Process_Para set DefaultValue='' where AD_Process_Para_ID=212;


-- update passwords from default
-- update ad_user set password = password||'SomeValueHere' where password is not null and ad_client_id in (11,0);

--update Attribute Set Instance fields to be a dropdown instead of special popup box
--actions:
	--move this section to a formal packin
	--update ad_column set AD_Reference_ID=18 where columnname = 'M_AttributeSetInstanceTo_ID';  --needs reference key
	--add m_product_id to M_AttributeSetInstance table to make choosing ASI more intuative
--notes:
	--this section is handy if you want a simple lot system.
	--this section reduces the flexibility and capabilies of Attribute Set Instances for the sake of simple lot management
	--if you are not happy with this change, change the ASI field back to the special form by using the next sql statement.
		-- update ad_column set AD_Reference_ID=35 where columnname = 'M_AttributeSetInstance_ID';
	--uncomment the below if this feature is desired
		--update ad_column set AD_Reference_ID=19 where columnname = 'M_AttributeSetInstance_ID' ; -- table direct
		--update ad_window set windowtype = 'M' where ad_window_id = 358; --make ASI window editable
		--update AD_Field set isreadonly = 'N', isquickentry='Y' where AD_Field_ID=12252; --m_attributeset_id
		--update AD_Field set isreadonly = 'N', isquickentry='Y' where AD_Field_ID=12255; --description
		--update AD_Column set isidentifier='N', seqno = null where AD_Table_ID=559; --remove existing identifiers and set following
		--update AD_Column set isidentifier='Y', seqno = 1 where AD_Column_ID = 8477; --m_attributeset
		--update AD_Column set isidentifier='Y', seqno = 2 where AD_Column_ID = 8479; --description


