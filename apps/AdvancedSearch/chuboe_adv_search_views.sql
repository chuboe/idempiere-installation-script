-- this file contains all the views for the Advanced Search window. Install these views first.

Create or replace view chuboe_adv_search_order as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.c_order_id, ol.c_orderline_id,
o.c_bpartner_id, o.c_bpartner_location_id,
o.bill_bpartner_id, o.bill_location_id,
ol.m_product_id, ol.c_charge_id, o.datepromised,
ol.line
from c_order o
join c_orderline ol on o.c_order_id = ol.c_order_id
;

Create or replace view chuboe_adv_search_inout as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.m_inout_id, ol.m_inoutline_id,
o.c_bpartner_id, o.c_bpartner_location_id,
ol.m_product_id, ol.c_charge_id, o.movementdate,
ol.line
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
ol.line
from c_invoice o
join c_invoiceline ol on o.c_invoice_id= ol.c_invoice_id
;

