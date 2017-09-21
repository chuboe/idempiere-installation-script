-- run this script using the following command:
-- psql -U adempiere -h localhost -d idempiere -f chuboe_favorite_default_changes.sql

--remove all default values from document types because they are not needed.
update c_doctype set isdefault='N';

--make certain tables high volume to promote a search box when window is opened.
-- doctype, 
update ad_table set ishighvolume = 'Y' where ad_table_id in (217);

--make all tabs default to grid view.
update ad_tab set issinglerow = 'N';

--make the GL Journal window more intuative for editing in grid view
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

--update Attribute Set Instance fields to be a drop	down instead of special popup box
--actions:
--move this section to a formal packin
--update ad_column set AD_Reference_ID=18 where columnname = 'M_AttributeSetInstanceTo_ID';  --needs reference key
--add m_product_id to M_AttributeSetInstance table to make choosing ASI more intuative
update ad_column set AD_Reference_ID=19 where columnname = 'M_AttributeSetInstance_ID' ; -- table direct
update ad_window set windowtype = 'M' where ad_window_id = 358; --make ASI window editable
update AD_Field set isreadonly = 'N', isquickentry='Y' where AD_Field_ID=12252; --m_attributeset_id
update AD_Field set isreadonly = 'N', isquickentry='Y' where AD_Field_ID=12255; --description
update AD_Column set isidentifier='N', seqno = null where AD_Table_ID=559; --remove existing identifiers and set following
update AD_Column set isidentifier='Y', seqno = 1 where AD_Column_ID = 8477; --m_attributeset
update AD_Column set isidentifier='Y', seqno = 2 where AD_Column_ID = 8479; --description


