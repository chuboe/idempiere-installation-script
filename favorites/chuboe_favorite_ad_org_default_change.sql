--the purpose of this scrit is to set the default org to '*' for most common objects.
--there are times when you might want some of these to be a specific org; however, the average company does not.

create table chuboe_favorite_ad_org_default_change as
select lower(tablename) as tablename from ad_table where lower(tablename) in ('m_product', 'c_bpartner', 'c_paymentterm', 'c_bank', 'c_bp_group', 'c_bp_relation', 'c_bpartner_location', 'ad_user', 'c_calendar', 'c_charge', 'c_uom', 'm_attribute', 'm_attributeset', 'm_pricelist', 'm_pricelist_version', 'm_product_category', 'r_request', 'r_requesttype', 'r_resolution', 'r_status', 's_resource', 'r_statuscategory')
;

--take a backup before update
create table chuboe_favorite_ad_org_default_change_orig as 
select ad_column_id, defaultvalue
from ad_column
where lower(columnname) = 'ad_org_id' 
and ad_table_id in
(select ad_table_id 
	from ad_table where lower(tablename) in 
		(select tablename from chuboe_favorite_ad_org_default_change)
)
;

update ad_column 
set defaultvalue = '0'
where lower(columnname) = 'ad_org_id' 
and ad_table_id in
(select ad_table_id 
	from ad_table where lower(tablename) in 
		(select tablename from chuboe_favorite_ad_org_default_change)
)
;

--use the following queries to put the tabs and fields back to their original state
--update ad_column set defaultvalue = (select defaultvalue from chuboe_favorite_ad_org_default_change_orig x where ad_column.ad_column_id = x.ad_column_id) where ad_column_id in (select ad_column_id from chuboe_favorite_ad_org_default_change_orig);