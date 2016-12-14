-- this file contains all the views for the Advanced Search window. Install these views first.

--Deactivate the existing duplicate tabs in Business Partner Info. Not performing this in Pack Out because of the ties to C_Order, C_Invioce, etc... tables. The back out is too dangerous.
update ad_tab
set isactive = 'N'
where ad_tab_id in (551, 552, 553, 554)
;

--Prevent Name2 from being the first field displayed when searching in Business Partner Info.
update ad_field
set seqno = 100
where ad_field_id = 9760
;

Create or replace view chuboe_adv_search_order as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.c_order_id, ol.c_orderline_id,
o.c_bpartner_id, o.c_bpartner_location_id,
o.bill_bpartner_id, o.bill_location_id,
ol.m_product_id, ol.c_charge_id, o.datepromised,
ol.line, o.issotrx
from c_order o
join c_orderline ol on o.c_order_id = ol.c_order_id
;

Create or replace view chuboe_adv_search_inout as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.m_inout_id, ol.m_inoutline_id,
o.c_bpartner_id, o.c_bpartner_location_id,
ol.m_product_id, ol.c_charge_id, o.movementdate,
ol.line, o.issotrx
from m_inout o
join m_inoutline ol on o.m_inout_id= ol.m_inout_id
;

Create or replace view chuboe_adv_search_invoice as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.c_invoice_id, ol.c_invoiceline_id,
o.c_bpartner_id, o.c_bpartner_location_id,
ol.m_product_id, ol.c_charge_id, o.dateinvoiced,
o.dateacct,
ol.line, o.issotrx
from c_invoice o
join c_invoiceline ol on o.c_invoice_id= ol.c_invoice_id
;

Create or replace view chuboe_adv_search_payment as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.c_payment_id, 
o.c_bpartner_id, o.c_charge_id, o.datetrx, o.dateacct,
o.c_invoice_id, o.isreceipt
from c_payment o
;

Create or replace view chuboe_adv_search_bp_loc as
select b.ad_client_id, b.ad_org_id,
b.created, b.createdby, b.updated, b.updatedby,
b.c_bpartner_id, b.name, b.name2,
bl.name as chuboe_bp_LocationName,
bl.isshipto, bl.isbillto, bl.isremitto, bl.ispayfrom,
l.address1, l.address2, l.address3, l.address4,
l.city, l.regionname
--action - need to left join in city and region and coalesce the above values
from c_bpartner b 
left outer join c_bpartner_location bl on b.c_bpartner_id = bl.c_bpartner_id
left outer join c_location l on bl.c_location_id = l.c_location_id
;