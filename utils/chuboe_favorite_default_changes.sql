-- run this script using the following command:
-- psql -U adempiere -h localhost -d idempiere -f chuboe_favorite_default_changes.sql

-- performance indexes
CREATE INDEX fact_acct_doc_chuboe_idx ON fact_acct USING btree (account_id, ad_table_id, record_id); -- improves BSD
CREATE INDEX fas_pa_chuboe_idx ON fact_acct_summary USING btree (account_id, ad_org_id, dateacct, pa_reportcube_id); -- improves finReport

--make certain tables high volume to promote a search box when window is opened. 
update ad_table set ishighvolume = 'Y' where ad_table_id in (217); -- doctype

--make all tabs default to grid view.
update ad_tab set issinglerow = 'N'; -- better for teaching new users iDempiere

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
update ad_column_id set seqnoselection = 99 where ad_column_id in
(
select ad_column_id from ad_column where isselectioncolumn = 'Y' and (seqnoselection is null or seqnoselection = 0)
);

-- Track changes on all tables
--update ad_table set ischangelog = 'Y' where lower(tablename) like 'chuboe%';

-- Make change log tracking default on all new tables
update AD_Column set defaultvalue = 'Y' where AD_Column_ID=8564;

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
update ad_column set AD_Reference_ID=19 where columnname = 'M_AttributeSetInstance_ID' ; -- table direct
update ad_window set windowtype = 'M' where ad_window_id = 358; --make ASI window editable
update AD_Field set isreadonly = 'N', isquickentry='Y' where AD_Field_ID=12252; --m_attributeset_id
update AD_Field set isreadonly = 'N', isquickentry='Y' where AD_Field_ID=12255; --description
update AD_Column set isidentifier='N', seqno = null where AD_Table_ID=559; --remove existing identifiers and set following
update AD_Column set isidentifier='Y', seqno = 1 where AD_Column_ID = 8477; --m_attributeset
update AD_Column set isidentifier='Y', seqno = 2 where AD_Column_ID = 8479; --description


