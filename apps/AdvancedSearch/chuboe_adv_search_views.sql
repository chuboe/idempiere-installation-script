-- this file contains all the views for the Advanced Search window. Install these views first.

Create or replace view chuboe_adv_search_order as
select o.ad_client_id, o.ad_org_id,
o.created, o.createdby, o.updated, o.updatedby,
o.documentno, o.c_order_id, ol.c_orderline_id,
o.c_bpartner_id, o.c_bpartner_location_id,
o.bill_bpartner_id, o.bill_location_id,
ol.m_product_id, ol.c_charge_id, o.datepromised
from c_order o
join c_orderline ol on o.c_order_id = ol.c_order_id
;

