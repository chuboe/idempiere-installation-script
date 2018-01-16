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
select io.ad_client_id, io.ad_org_id,
io.created, io.createdby, io.updated, io.updatedby,
io.documentno, io.m_inout_id, iol.m_inoutline_id,
io.c_bpartner_id, io.c_bpartner_location_id,
iol.m_product_id, iol.c_charge_id, io.movementdate,
iol.line, io.issotrx
from m_inout io
join m_inoutline iol on io.m_inout_id= iol.m_inout_id
;

Create or replace view chuboe_adv_search_invoice as
select i.ad_client_id, i.ad_org_id,
i.created, i.createdby, i.updated, i.updatedby,
i.documentno, i.c_invoice_id, il.c_invoiceline_id,
i.c_bpartner_id, i.c_bpartner_location_id,
il.m_product_id, il.c_charge_id, i.dateinvoiced,
i.dateacct,
il.line, i.issotrx
from c_invoice i
join c_invoiceline il on i.c_invoice_id= il.c_invoice_id
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

-- Created flattened search view for Requisitions
CREATE OR REPLACE VIEW chuboe_adv_search_requisition AS 
SELECT r.ad_client_id, r.ad_org_id, r.created,
r.createdby, r.updated, r.updatedby, r.documentno, 
r.priorityrule, r.m_requisition_id, r.ad_user_id,
r.datedoc, r.daterequired, rl.m_requisitionline_id, 
rl.c_orderline_id, rl.c_bpartner_id, rl.m_product_id,
rl.c_charge_id, rl.line, rl.qty, rl.linenetamt, 
--COALESCE(rl.c_project_id, r.c_project_id) AS c_project_id --iDempiere does not have a project on Requisition out of the box
null::numeric as c_project_id
FROM m_requisition r 
JOIN m_requisitionline rl ON r.m_requisition_id = rl.m_requisition_id
;