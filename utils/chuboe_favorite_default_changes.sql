-- run this script using the following commands:
-- source chuboe.properties
-- psql -U $CHUBOE_PROP_DB_USERNAME -h $CHUBOE_PROP_DB_HOST -d $CHUBOE_PROP_DB_NAME -f chuboe_favorite_default_changes.sql

-- Need to account for the following:
-- Add Created and Updated fields to Table, Column, Window, Tab, Field
-- Need to remember to add Charge as default Accounting Dimension for new customers

-- performance indexes
CREATE INDEX fact_acct_doc_chuboe_idx ON fact_acct USING btree (account_id, ad_table_id, record_id); -- improves BSD
CREATE INDEX fas_pa_chuboe_idx ON fact_acct_summary USING btree (account_id, ad_org_id, dateacct, pa_reportcube_id); -- improves finReport
CREATE INDEX chuboe_journalline_hdr_idx ON gl_journalline USING btree (gl_journal_id);
CREATE INDEX chuboe_requpdate_req_idx ON r_requestupdate USING btree (r_request_id);
create index chuboe_order_tax_hdr_idx on c_ordertax(c_order_id);
create index chuboe_invoice_tax_hdr_idx on c_invoicetax(c_invoice_id);

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

-- Default Window, Tab and Field => Tab subtab => Create fields process => From to today's date since this is the most common scenario
update AD_Process_Para set DefaultValue = '@#Date@' where AD_Process_Para_ID=200077;

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


