-- the purpose of this script is to make data entry into order, invoice and shipment/receipt lines easier. 
-- note at the bottom of the script three is are undo scripts

create table chuboe_favorite_line_entry_change as
select lower(tablename) as tablename from ad_table where lower(tablename) in ('c_orderline', 'c_invoiceline','m_inoutline')
;

create table chuboe_ad_field_orig as 
select ad_field_id, seqnogrid 
from ad_field
where ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_tab
set issinglerow = 'N'
where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
)
;

update ad_field
set seqnogrid = seqnogrid + 200
where ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 10
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'line'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 20
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'm_product_id'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 30
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'c_charge_id'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 40
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'qtyentered'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 50
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'm_locator_id'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 60
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'description'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

update ad_field
set seqnogrid = 70
where ad_column_id in
(
select ad_column_id from ad_column where lower(columnname) = 'linenetamt'
) 
and 
ad_tab_id in
(select ad_tab_id
from ad_tab where ad_table_id in
(select ad_table_id 
from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change)
))
;

--use the following queries to put the tabs and fields back to their original state
--update ad_field set seqnogrid = (select seqnogrid from chuboe_ad_field_orig x where ad_field.ad_field_id = x.ad_field_id) where ad_field_id in (select ad_field_id from chuboe_ad_field_orig);
--update ad_tab set issinglerow = 'Y' where ad_table_id in (select ad_table_id from ad_table where lower(tablename) in (select tablename from chuboe_favorite_line_entry_change));