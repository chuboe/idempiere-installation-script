-- The purpose of this script is to help you create views that are easily used inside a BI or analytics tool.

--Missing Tables
-- BP Group and Product Cat to every table
-- Invoice needs order shipping BP details
-- locator
-- price list
-- currency

----- Section 2 ----- Create the views needed to resolve keys into human readable words
DROP VIEW IF EXISTS bi_production_line;
DROP VIEW IF EXISTS bi_production;
DROP VIEW IF EXISTS bi_request;
DROP VIEW IF EXISTS bi_requisition_line;
DROP VIEW IF EXISTS bi_requisition;
DROP VIEW IF EXISTS bi_inout_line;
DROP VIEW IF EXISTS bi_inout;
DROP VIEW IF EXISTS bi_invoice_line;
DROP VIEW IF EXISTS bi_invoice;
DROP VIEW IF EXISTS bi_order_line;
DROP VIEW IF EXISTS bi_order;
DROP VIEW IF EXISTS bi_project;
DROP VIEW IF EXISTS bi_product;
DROP VIEW IF EXISTS bi_charge;
DROP VIEW IF EXISTS bi_locator;
DROP VIEW IF EXISTS bi_warehouse;
DROP VIEW IF EXISTS bi_user;
DROP VIEW IF EXISTS bi_bploc;
DROP VIEW IF EXISTS bi_location;
DROP VIEW IF EXISTS bi_bpartner;
DROP VIEW IF EXISTS bi_uom;
DROP VIEW IF EXISTS bi_tax;
DROP VIEW IF EXISTS bi_tax_category;
DROP VIEW IF EXISTS bi_org;
DROP VIEW IF EXISTS bi_client;

CREATE VIEW bi_client AS
SELECT c.name AS client_name,
c.ad_client_id as client_id
FROM ad_client c;
SELECT 'c.'||column_name||',' as client FROM information_schema.columns WHERE  table_name   = 'bi_client';
--SELECT COUNT(*) as client_count FROM bi_client;

CREATE VIEW bi_org AS
SELECT 
o.name AS org_name,
o.value AS org_search_key, o.ad_org_id as org_id,
o.isactive AS org_active
FROM ad_org o
WHERE o.issummary = 'N'::bpchar;
SELECT 'o.'||column_name||',' as org FROM information_schema.columns WHERE  table_name   = 'bi_org';
--SELECT COUNT(*) as org_count FROM bi_org;

CREATE VIEW bi_tax_category as
SELECT
c.*,
-- assuming no org needed
tc.c_taxcategory_id as tax_category_id,
tc.name as tax_category_name,
tc.description as tax_category_description
from c_taxcategory tc
join bi_client c on tc.ad_client_id = c.client_id;
SELECT 'tc.'||column_name||',' as tax_category FROM information_schema.columns WHERE  table_name   = 'bi_tax_category';
--SELECT COUNT(*) as tax_cat_count FROM bi_tax_category;

CREATE VIEW bi_tax as
SELECT
c.*,
t.c_tax_id as tax_id,
t.name as tax_name,
t.description as tax_description,
t.isactive as tax_active,
t.rate as tax_rate,
t.taxindicator as tax_indicator,
tc.tax_category_name,
tc.tax_category_description
FROM c_tax t
JOIN bi_client c on t.ad_client_id = c.client_id
JOIN bi_tax_category tc on t.c_taxcategory_id = tc.tax_category_id
;
SELECT 't.'||column_name||',' as tax FROM information_schema.columns WHERE  table_name   = 'bi_tax';
--SELECT COUNT(*) as tax_count FROM bi_tax;


CREATE VIEW bi_uom AS
SELECT uom.c_uom_id as uom_id,
c.*,
-- assuming no org needed
uom.name AS uom_name, 
uom.uomsymbol AS uom_search_key, 
uom.isactive AS uom_active
FROM c_uom uom
JOIN bi_client c on uom.ad_client_id=c.client_id;
SELECT 'uom.'||column_name||',' as uom FROM information_schema.columns WHERE  table_name   = 'bi_uom';
--SELECT COUNT(*) as uom_count FROM bi_uom;

CREATE VIEW bi_bpartner AS
SELECT
c.*,
-- assuming no org needed
bp.c_bpartner_id as bpartner_id,
bp.value AS bpartner_search_key,
bp.name AS bpartner_name,
bp.name2 AS bpartner_name2,
bp.created AS bpartner_created,
bp.updated as bpartner_updated,
bp.iscustomer AS bpartner_customer,
bp.isvendor AS bpartner_vendor,
bp.isemployee AS bpartner_employee,
bpg.value as bpartner_group_search_key,
bpg.name as bpartner_group_name,
bpg.description as bpartner_group_description
FROM c_bpartner bp
JOIN bi_client c on bp.ad_client_id = c.client_id
JOIN bi_org o on bp.ad_org_id = o.org_id
JOIN C_BP_Group bpg on bp.C_BP_Group_id = bpg.C_BP_Group_id
;
SELECT 'bp.'||column_name||',' as bpartner FROM information_schema.columns WHERE  table_name   = 'bi_bpartner';
--SELECT COUNT(*) as bp_count FROM bi_bpartner;

CREATE VIEW bi_location AS
SELECT
l.c_location_id as loc_id,
l.address1 AS loc_address1,
l.address2 AS loc_address2,
l.address3 AS loc_address3,
l.address4 AS loc_address4,
l.city AS loc_city,
l.regionname AS loc_state,
country.countrycode AS loc_country_code,
country.name AS loc_country_name
FROM c_location l
JOIN c_country country ON l.c_country_id = country.c_country_id
;
SELECT 'loc.'||column_name||',' as loc FROM information_schema.columns WHERE  table_name   = 'bi_location';
--SELECT COUNT(*) as loc_count FROM bi_location;

CREATE VIEW bi_bploc AS
SELECT
c.*,

bpl.c_bpartner_location_id as bpartner_location_id,

bp.bpartner_search_key,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_updated,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,

bpl.name AS bploc_name,
bpl.created as bploc_created,
bpl.updated as bploc_updated,

loc.loc_address1 as bploc_address1,
loc.loc_address2 as bploc_address2,
loc.loc_address3 as bploc_address3,
loc.loc_address4 as bploc_address4,
loc.loc_city as bploc_city,
loc.loc_state as bploc_state,
loc.loc_country_code as bploc_country_code,
loc.loc_country_name as bploc_country_name

FROM c_bpartner_location bpl
JOIN bi_bpartner bp on bpl.c_bpartner_id = bp.bpartner_id
JOIN bi_client c ON bpl.ad_client_id = c.client_id
JOIN bi_org o on bpl.ad_org_id = o.org_id
join bi_location loc on bpl.c_location_id = loc.loc_id
;
SELECT 'bploc.'||column_name||',' as bploc FROM information_schema.columns WHERE  table_name   = 'bi_bploc';
--SELECT COUNT(*) as bploc_count FROM bi_bploc;

CREATE VIEW bi_user AS
SELECT
c.*,
-- assuming no org needed
u.ad_user_id as user_id,
u.value as user_search_key,
u.name as user_name,
u.description as user_description,
u.email as user_email,
u.phone as user_phone,

bp.bpartner_search_key,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_updated,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,
bp.bpartner_group_search_key,
bp.bpartner_group_name,
bp.bpartner_group_description,

bploc.bploc_name as user_bploc_name,
bploc.bploc_created as user_bploc_created,
bploc.bploc_updated as user_bploc_updated,
bploc.bploc_address1 as user_bploc_address1,
bploc.bploc_address2 as user_bploc_address2,
bploc.bploc_address3 as user_bploc_address3,
bploc.bploc_address4 as user_bploc_address4,
bploc.bploc_city as user_bploc_city,
bploc.bploc_state as user_bploc_state,
bploc.bploc_country_code as user_bploc_country_code,
bploc.bploc_country_name as user_bploc_country_name

FROM ad_user u
JOIN bi_client c on u.ad_client_id = c.client_id
LEFT JOIN bi_bpartner bp on u.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_bploc bploc on u.c_bpartner_location_id = bploc.bpartner_location_id
;
SELECT 'u.'||column_name||',' as user FROM information_schema.columns WHERE  table_name   = 'bi_user';
--SELECT COUNT(*) as user_count FROM bi_user;

CREATE VIEW bi_warehouse AS
SELECT
c.*,
o.*,
w.m_warehouse_id as warehouse_id,
w.value as warehouse_search_key,
w.name as warehouse_name,
w.description as warehouse_description,
w.isactive as warehouse_active,
w.isintransit as warehouse_in_transit,
w.isdisallownegativeinv as warehouse_prevent_negative_inventory,

loc.loc_address1 as warehouse_loc_address1,
loc.loc_address2 as warehouse_loc_address2,
loc.loc_address3 as warehouse_loc_address3,
loc.loc_address4 as warehouse_loc_address4,
loc.loc_city as warehouse_loc_city,
loc.loc_state as warehouse_loc_state,
loc.loc_country_code as warehouse_loc_country_code,
loc.loc_country_name as warehouse_loc_country_name

FROM m_warehouse w
join bi_client c on w.ad_client_id = c.client_id
join bi_org o on w.ad_org_id = o.org_id
left join bi_location loc on w.c_location_id = loc.loc_id
;
SELECT 'wh.'||column_name||',' as warehouse FROM information_schema.columns WHERE  table_name   = 'bi_warehouse';
--SELECT COUNT(*) as wh_count FROM bi_warehouse;

CREATE VIEW bi_locator AS
SELECT
wh.*,
locator.m_locator_id as locator_id,
locator.value as locator_search_key,
locator.x as locator_x,
locator.y as locator_y,
locator.z as locator_z,
mt.name as locator_type

FROM m_locator locator
JOIN bi_warehouse wh on locator.m_warehouse_id = wh.warehouse_id
JOIN M_LocatorType mt on locator.M_LocatorType_id = mt.M_LocatorType_id
;
SELECT 'locator.'||column_name||',' as locator FROM information_schema.columns WHERE  table_name   = 'bi_locator';
--SELECT COUNT(*) as locator_count FROM bi_locator;

CREATE VIEW bi_charge AS
SELECT 
c.*,
chg.c_charge_id as charge_id,
chg.name AS charge_name,
chg.description AS charge_description,
chg.isactive as charge_active,
chg.created as charge_created,
chg.updated as charge_updated
FROM c_charge chg
JOIN bi_client c on chg.ad_client_id=c.client_id;
SELECT 'chg.'||column_name||',' as charge FROM information_schema.columns WHERE  table_name   = 'bi_charge';
--SELECT COUNT(*) as charge_count FROM bi_charge;

CREATE VIEW bi_product AS
SELECT
c.*,
p.m_product_id as product_id,
p.value as product_search_key,
p.created as product_created,
p.updated as product_updated,
p.name as product_name,
p.description as product_description,
p.documentnote as product_document_note,
p.isactive as product_active,
prodtype.name as product_type,
pc.name as product_category_name,
uom.uom_name
from m_product p
join AD_Ref_List prodtype on p.producttype = prodtype.value AND prodtype.AD_Reference_ID=270
join m_product_category pc on p.m_product_category_id = pc.m_product_category_id
join bi_uom uom on p.c_uom_id = uom.uom_id
join bi_client c on p.ad_client_id = c.client_id
;
SELECT 'prod.'||column_name||',' as product FROM information_schema.columns WHERE  table_name   = 'bi_product';
--SELECT COUNT(*) as product_count FROM bi_product;

CREATE VIEW bi_project AS
SELECT
c.*,
o.*,
proj.c_project_id as project_id,
proj.value as project_search_key,
proj.name as project_name,
proj.description as project_description,
proj.isactive as project_active,
proj.issummary as project_summary,
proj.note as project_note,
proj.datecontract as project_date_contract,
proj.datefinish as project_date_finish,
level.name as project_line_level,

bp.bpartner_search_key as project_bpartner_search_key,
bp.bpartner_name as project_bpartner_name,
bp.bpartner_name2 as project_bpartner_name2,
bp.bpartner_created as project_bpartner_created,
bp.bpartner_updated as project_bpartner_updated,
bp.bpartner_customer as project_bpartner_customer,
bp.bpartner_vendor as project_bpartner_vendor,
bp.bpartner_employee as project_bpartner_employee,
bp.bpartner_group_search_key as project_bpartner_group_search_key,
bp.bpartner_group_name as project_bpartner_group_name,
bp.bpartner_group_description as project_bpartner_group_description,

bpsr.bpartner_search_key as project_agent_search_key,
bpsr.bpartner_name as project_agent_name,
bpsr.bpartner_name2 as project_agent_name2,
bpsr.bpartner_created as project_agent_created,
bpsr.bpartner_updated as project_agent_updated,
bpsr.bpartner_customer as project_agent_customer,
bpsr.bpartner_vendor as project_agent_vendor,
bpsr.bpartner_employee as project_agent_employee,
bpsr.bpartner_group_search_key as project_agent_group_search_key,
bpsr.bpartner_group_name as project_agent_group_name,
bpsr.bpartner_group_description as prject_agent_group_description,

wh.warehouse_search_key as project_warehouse_search_key,
wh.warehouse_name as project_warehouse_name,
wh.warehouse_description as project_warehouse_description,
wh.warehouse_active as project_warehouse_active,
wh.warehouse_in_transit as project_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as project_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as project_warehouse_loc_address1,
wh.warehouse_loc_address2 as project_warehouse_loc_address2,
wh.warehouse_loc_address3 as project_warehouse_loc_address3,
wh.warehouse_loc_address4 as project_warehouse_loc_address4,
wh.warehouse_loc_city as project_warehouse_loc_city,
wh.warehouse_loc_state as project_warehouse_loc_state,
wh.warehouse_loc_country_code as project_warehouse_loc_country_code,
wh.warehouse_loc_country_name as project_warehouse_loc_country_name

FROM c_project proj
JOIN bi_client c on proj.ad_client_id = c.client_id
JOIN bi_org o on proj.ad_org_id = o.org_id
LEFT JOIN bi_bpartner bp on proj.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_bpartner bpsr on proj.c_bpartnersr_id = bp.bpartner_id
LEFT JOIN bi_warehouse wh on proj.m_warehouse_id = wh.warehouse_id
LEFT JOIN AD_Ref_List level on proj.projectlinelevel = level.value AND level.AD_Reference_ID=384
;
SELECT 'proj.'||column_name||',' as project FROM information_schema.columns WHERE  table_name   = 'bi_project';
--SELECT COUNT(*) as project_count FROM bi_project;

CREATE VIEW bi_order AS
SELECT
c.*,
o.*,
ord.c_order_id as order_id,
ord.documentno as Order_DocumentNo,
dt.name as order_document_type,
ord.poreference as order_order_reference,
ord.description as order_description,
ord.datepromised as order_date_promised,
ord.dateordered as Order_date_ordered,
delrule.name as order_delivery_rule,
invrule.name as order_invoice_rule,
ord.priorityrule as order_priority,

ord.grandtotal as Order_Grand_total,
ord.issotrx as Order_Sales_Transaction,
ord.docstatus as Order_document_status,
ord.created as order_created,
ord.updated as order_updated,

bp.bpartner_search_key as order_ship_bpartner_search_key,
bp.bpartner_name as order_ship_bpartner_name,
bp.bpartner_name2 as order_ship_bpartner_name2,
bp.bpartner_created as order_ship_bpartner_created,
bp.bpartner_updated as order_ship_bpartner_updated,
bp.bpartner_customer as order_ship_bpartner_customer,
bp.bpartner_vendor as order_ship_bpartner_vendor,
bp.bpartner_employee as order_ship_bpartner_employee,
bp.bpartner_group_search_key as order_ship_bpartner_group_search_key,
bp.bpartner_group_name as order_ship_bpartner_group_name,
bp.bpartner_group_description as order_ship_bpartner_group_description,

bploc.bploc_name as order_ship_bploc_name,
bploc.bploc_address1 as order_ship_bploc_address1,
bploc.bploc_address2 as order_ship_bploc_address2,
bploc.bploc_address3 as order_ship_bploc_address3,
bploc.bploc_address4 as order_ship_bploc_address4,
bploc.bploc_city as order_ship_bploc_city,
bploc.bploc_state as order_ship_bploc_state,
bploc.bploc_country_code as order_ship_bploc_country_code,
bploc.bploc_country_name as order_ship_bploc_country_name,

bpinv.bpartner_search_key as order_invoice_bpartner_search_key,
bpinv.bpartner_name as order_invoice_bpartner_name,
bpinv.bpartner_name2 as order_invoice_bpartner_name2,
bpinv.bpartner_created as order_invoice_bpartner_created,
bpinv.bpartner_updated as order_invoice_bpartner_updated,
bpinv.bpartner_customer as order_invoice_bpartner_customer,
bpinv.bpartner_vendor as order_invoice_bpartner_vendor,
bpinv.bpartner_employee as order_invoice_bpartner_employee,
bpinv.bpartner_group_search_key as order_invoice_bpartner_group_search_key,
bpinv.bpartner_group_name as order_invoice_bpartner_group_name,
bpinv.bpartner_group_description as order_invoice_bpartner_group_description,

bplocinv.bploc_name as order_invoice_bploc_name,
bplocinv.bploc_address1 as order_invoice_bploc_address1,
bplocinv.bploc_address2 as order_invoice_bploc_address2,
bplocinv.bploc_address3 as order_invoice_bploc_address3,
bplocinv.bploc_address4 as order_invoice_bploc_address4,
bplocinv.bploc_city as order_invoice_bploc_city,
bplocinv.bploc_state as order_invoice_bploc_state,
bplocinv.bploc_country_code as order_invoice_bploc_country_code,
bplocinv.bploc_country_name as order_invoice_bploc_country_name,

wh.warehouse_search_key as order_warehouse_search_key,
wh.warehouse_name as order_warehouse_name,
wh.warehouse_description as order_warehouse_description,
wh.warehouse_active as order_warehouse_active,
wh.warehouse_in_transit as order_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as order_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as order_warehouse_loc_address1,
wh.warehouse_loc_address2 as order_warehouse_loc_address2,
wh.warehouse_loc_address3 as order_warehouse_loc_address3,
wh.warehouse_loc_address4 as order_warehouse_loc_address4,
wh.warehouse_loc_city as order_warehouse_loc_city,
wh.warehouse_loc_state as order_warehouse_loc_state,
wh.warehouse_loc_country_code as order_warehouse_loc_country_code,
wh.warehouse_loc_country_name as order_warehouse_loc_country_name

from c_order ord
join bi_bpartner bp on ord.c_bpartner_id = bp.bpartner_id
join bi_bpartner bpinv on ord.bill_bpartner_id = bpinv.bpartner_id
join bi_bploc bploc on ord.c_bpartner_location_id = bploc.bpartner_location_id
join bi_bploc bplocinv on ord.bill_location_id = bplocinv.bpartner_location_id
join bi_client c on ord.ad_client_id = c.client_id
join bi_org o on ord.ad_org_id = o.org_id
join c_doctype dt on ord.c_doctype_id = dt.c_doctype_id
left join AD_Ref_List delrule on ord.deliveryrule = delrule.value and delrule.AD_Reference_ID=151
left join AD_Ref_List invrule on ord.invoicerule = invrule.value and invrule.AD_Reference_ID=150
left join bi_warehouse wh on ord.m_warehouse_id = wh.warehouse_id
;
SELECT 'order.'||column_name||',' as order FROM information_schema.columns WHERE  table_name   = 'bi_order';
--SELECT COUNT(*) as order_count FROM bi_order;

CREATE VIEW bi_order_line AS
SELECT 
o.*,
ol.c_orderline_id as orderline_id,
ol.line as order_line_lineno,
ol.qtyordered as order_line_qty_ordered,
ol.qtyentered as order_line_qty_entered,
ol.qtyinvoiced as order_line_qty_invoiced,
ol.qtydelivered as order_line_qty_delivered,
ol.description as order_line_description,
ol.priceentered as order_line_price_entered,
ol.linenetamt as order_line_linenetamt,
ol.created as order_line_created,
ol.updated as order_line_updated,

prod.product_search_key as order_line_product_search_key,
prod.product_name as order_line_product_name,
prod.product_description as order_line_product_description,
prod.product_document_note as order_line_product_document_note,
prod.product_category_name as order_line_product_category_name,

uom.uom_name as order_line_uom_name,
uom.uom_search_key as order_line_uom_search_key,

chg.charge_name as order_line_charge_name,
chg.charge_description as order_line_charge_description,

t.tax_name as order_line_tax_name,
t.tax_description as order_line_tax_description,
t.tax_active as order_line_tax_active,
t.tax_rate as order_line_tax_rate,
t.tax_indicator as order_line_tax_indicator ,
t.tax_category_name as order_line_tax_category_name,
t.tax_category_description as order_line_tax_category_description,

bploc.bploc_name as order_line_bploc_name,
bploc.bploc_created as order_line_bploc_created,
bploc.bploc_updated as order_line_bploc_updated,
bploc.bploc_address1 as order_line_bploc_address1,
bploc.bploc_address2 as order_line_bploc_address2,
bploc.bploc_address3 as order_line_bploc_address3,
bploc.bploc_address4 as order_line_bploc_address4,
bploc.bploc_city as order_line_bploc_city,
bploc.bploc_state as order_line_bploc_state,
bploc.bploc_country_code as order_line_bploc_country_code,
bploc.bploc_country_name as order_line_bploc_country_name

FROM c_orderline ol
JOIN bi_order o ON ol.c_order_id = o.order_id
LEFT JOIN bi_product prod on ol.m_product_id = prod.product_id
LEFT JOIN bi_charge chg ON ol.c_charge_id = chg.charge_id
JOIN bi_uom uom on ol.c_uom_id = uom.uom_id
JOIN bi_bploc bploc on ol.c_bpartner_location_id = bploc.bpartner_location_id
LEFT JOIN bi_tax t on ol.c_tax_id = t.tax_id
;
SELECT 'orderline.'||column_name||',' as orderline FROM information_schema.columns WHERE  table_name   = 'bi_order_line';
--SELECT COUNT(*) as order_line_count FROM bi_order_line;

CREATE VIEW bi_invoice AS
SELECT
c.*,
o.*,
inv.c_invoice_id as invoice_id,
inv.documentno as Invoice_DocumentNo,
dt.name as invoice_doctype_name,
inv.description as invoice_description,
inv.poreference as invoice_order_reference,
inv.grandtotal AS Invoice_Grand_total,
inv.issotrx as Invoice_Sales_Transaction,
inv.docstatus as Invoice_document_status,
inv.dateinvoiced as Invoice_date_invoiced,
inv.dateacct as Invoice_date_acct,
inv.created as invoice_created,
inv.updated as invoice_updated,

bp.bpartner_search_key as invoice_bpartner_search_key,
bp.bpartner_name as invoice_bpartner_name,
bp.bpartner_name2 as invoice_bpartner_name2,
bp.bpartner_created as invoice_bpartner_created,
bp.bpartner_customer as invoice_bpartner_customer,
bp.bpartner_vendor as invoice_bpartner_vendor,
bp.bpartner_employee as invoice_bpartner_employee,
bp.bpartner_group_search_key as invoice_bpartner_group_search_key,
bp.bpartner_group_name as invoice_bpartner_group_name,
bp.bpartner_group_description as invoice_bpartner_group_description,

bpl.bploc_name as invoice_bploc_name,
bpl.bploc_address1 as invoice_bploc_address1,
bpl.bploc_address2 as invoice_bploc_address2,
bpl.bploc_address3 as invoice_bploc_address3,
bpl.bploc_address4 as invoice_bploc_address4,
bpl.bploc_city as invoice_bploc_city,
bpl.bploc_state as invoice_bploc_state,
bpl.bploc_country_code as invoice_bploc_country_code,
bpl.bploc_country_name as invoice_bploc_country_name

FROM c_invoice inv
JOIN bi_bpartner bp ON inv.c_bpartner_id = bp.bpartner_id
JOIN bi_bploc bpl ON inv.c_bpartner_location_id = bpl.bpartner_location_id
JOIN bi_client c ON inv.ad_client_id = c.client_id
JOIN bi_org o ON inv.ad_org_id = o.org_id
JOIN c_doctype dt ON inv.c_doctype_id = dt.c_doctype_id
;
SELECT 'invoice.'||column_name||',' as invoice FROM information_schema.columns WHERE  table_name   = 'bi_invoice';
--SELECT COUNT(*) as invoice_count FROM bi_invoice;

CREATE VIEW bi_invoice_line AS
SELECT 
c.*,
o.*,
invoice.invoice_documentno,
invoice.invoice_doctype_name,
invoice.invoice_description,
invoice.invoice_order_reference,
invoice.invoice_grand_total,
invoice.invoice_sales_transaction,
invoice.invoice_document_status,
invoice.invoice_date_invoiced,
invoice.invoice_date_acct,
invoice.invoice_created,
invoice.invoice_updated,
invoice.invoice_bpartner_search_key,
invoice.invoice_bpartner_name,
invoice.invoice_bpartner_name2,
invoice.invoice_bpartner_created,
invoice.invoice_bpartner_customer,
invoice.invoice_bpartner_vendor,
invoice.invoice_bpartner_employee,
invoice.invoice_bpartner_group_search_key,
invoice.invoice_bpartner_group_name,
invoice.invoice_bpartner_group_description,
invoice.invoice_bploc_name,
invoice.invoice_bploc_address1,
invoice.invoice_bploc_address2,
invoice.invoice_bploc_address3,
invoice.invoice_bploc_address4,
invoice.invoice_bploc_city,
invoice.invoice_bploc_state,
invoice.invoice_bploc_country_code,
invoice.invoice_bploc_country_name,

il.c_invoiceline_id as invoiceline_id,
il.line as invoice_line_lineno,
il.description as invoice_line_description,
il.qtyinvoiced as invoice_line_qty_invoiced, 
il.priceactual as invoice_line_price_actual,
il.taxamt as invoice_line_tax_amt,
il.linetotalamt as invoice_line_linetotalamt,
il.linenetamt as invoice_line_linenetamt, 
il.created as invoice_line_created,
il.updated as invoice_line_updated,

prod.product_search_key as invoice_line_product_search_key,
prod.product_created as invoice_line_product_created,
prod.product_updated as invoice_line_product_updated,
prod.product_name as invoice_line_product_name,
prod.product_description as invoice_line_product_description,
prod.product_document_note as invoice_line_product_document_note,
prod.product_active as invoice_line_product_active,
prod.product_type as invoice_line_product_type,
prod.product_category_name as invoice_line_product_category_name,

chg.charge_name as invoice_line_charge_name,
chg.charge_description as invoice_line_charge_description,
chg.charge_active as invoice_line_charge_active,
chg.charge_created as invoice_line_charge_created,
chg.charge_updated as invoice_line_charge_updated,

t.tax_name as invoice_line_tax_name,
t.tax_description as invoice_line_tax_description,
t.tax_active as invoice_line_tax_active,
t.tax_rate as invoice_line_tax_rate,
t.tax_indicator as invoice_line_tax_indicator,
t.tax_category_name as invoice_line_tax_category_name,
t.tax_category_description as invoice_line_tax_category_description,

uom.uom_name as invoice_line_uom_name,
uom.uom_search_key as invoice_line_uom_search_key

FROM c_invoiceline il 
JOIN bi_client c on il.ad_client_id = c.client_id
JOIN bi_org o on il.ad_org_id = o.org_id
JOIN bi_invoice invoice ON il.c_invoice_id = invoice.invoice_id
LEFT JOIN bi_product prod ON il.m_product_id = prod.product_id
LEFT JOIN bi_uom uom ON il.c_uom_id = uom.uom_id
LEFT JOIN bi_charge chg ON il.c_charge_id = chg.charge_id
LEFT JOIN bi_tax t on il.c_tax_id = t.tax_id
;
SELECT 'invoiceline.'||column_name||',' as invoiceline FROM information_schema.columns WHERE  table_name   = 'bi_invoice_line';
--SELECT COUNT(*) as invoice_line_count FROM bi_invoice_line;

CREATE VIEW bi_inout AS
SELECT 
c.*,
o.*,
io.m_inout_id as inout_id,
io.issotrx AS InOut_Sales_Transaction,
io.documentno AS InOut_DocumentNo,
io.docaction AS InOut_document_action,
io.docstatus AS InOut_document_status,
dt.name AS InOut_doctype_name,
io.description AS InOut_description,
io.dateordered AS InOut_date_ordered,
io.movementdate as inout_movement_date,
io.created as inout_created,
io.updated as inout_updated,
bp.bpartner_search_key as inout_bpartner_search_key,
bp.bpartner_name as inout_bpartner_name,
bp.bpartner_name2 as inout_bpartner_name2,
bp.bpartner_created as inout_bpartner_created,
bp.bpartner_customer as inout_bpartner_customer,
bp.bpartner_vendor as inout_bpartner_vendor,
bp.bpartner_employee as inout_bpartner_employee,
bp.bpartner_group_search_key as inout_bpartner_group_search_key,
bp.bpartner_group_name as inout_bpartner_group_name,
bp.bpartner_group_description as inout_bpartner_group_description,

bpl.bploc_name as inout_bploc_name,
bpl.bploc_address1 as inout_bploc_address1,
bpl.bploc_address2 as inout_bploc_address2,
bpl.bploc_address3 as inout_bploc_address3,
bpl.bploc_address4 as inout_bploc_address4,
bpl.bploc_city as inout_bploc_city,
bpl.bploc_state as inout_bploc_state,
bpl.bploc_country_code as inout_bploc_country_code,
bpl.bploc_country_name as inout_bploc_country_name,

wh.warehouse_search_key as inout_warehouse_search_key,
wh.warehouse_name as inout_warehouse_name,
wh.warehouse_description as inout_warehouse_description,
wh.warehouse_active as inout_warehouse_active,
wh.warehouse_in_transit as inout_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as inout_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as inout_warehouse_loc_address1,
wh.warehouse_loc_address2 as inout_warehouse_loc_address2,
wh.warehouse_loc_address3 as inout_warehouse_loc_address3,
wh.warehouse_loc_address4 as inout_warehouse_loc_address4,
wh.warehouse_loc_city as inout_warehouse_loc_city,
wh.warehouse_loc_state as inout_warehouse_loc_state,
wh.warehouse_loc_country_code as inout_warehouse_loc_country_code,
wh.warehouse_loc_country_name as inout_warehouse_loc_country_name,

ord.order_DocumentNo,
ord.order_Grand_total,
ord.order_date_ordered,
inv.Invoice_DocumentNo,
inv.Invoice_Grand_total,
inv.Invoice_Sales_Transaction,
inv.Invoice_document_status,
inv.Invoice_date_invoiced

FROM m_inout io
JOIN bi_bpartner bp ON io.c_bpartner_id = bp.bpartner_id
LEFT JOIN bi_bploc bpl ON io.c_bpartner_location_id = bpl.bpartner_location_id
JOIN bi_client c ON io.ad_client_id = c.client_id
JOIN bi_org o ON io.ad_org_id = o.org_id
JOIN c_doctype dt ON io.c_doctype_id = dt.c_doctype_id
LEFT JOIN bi_order ord ON io.c_order_id = ord.order_id
LEFT JOIN bi_invoice inv ON io.c_invoice_id = inv.invoice_id
LEFT JOIN bi_warehouse wh on io.m_warehouse_id = wh.warehouse_id
;
SELECT 'inout.'||column_name||',' as inout FROM information_schema.columns WHERE  table_name   = 'bi_inout';
--SELECT COUNT(*) as inout_count FROM bi_inout;

CREATE VIEW bi_inout_line AS 
SELECT
c.*,
o.org_name,
o.org_search_key,

io.InOut_Sales_Transaction,
io.InOut_DocumentNo,
io.InOut_document_action,
io.InOut_document_status,
io.InOut_doctype_name,
io.InOut_description,
io.InOut_date_ordered,
io.InOut_movement_date,

ol.order_line_lineno,
ol.order_line_qty_ordered,
ol.order_line_qty_invoiced,
ol.order_line_description,
ol.order_line_linenetamt,

iol.m_inoutline_id as inoutline_id,
iol.line as inout_line_lineno,
iol.description as inout_line_description,
iol.movementqty as inout_line_movement_qty,
iol.created as inout_line_created,
iol.updated as inout_line_updated,

p.product_search_key as inout_line_product_search_key,
p.product_name as inout_line_product_name,
p.product_description as inout_line_product_description,
p.product_document_note as inout_line_product_document_note,
p.product_active as inout_line_product_active,
p.product_category_name as inout_line_product_category_name,

uom.uom_name as inout_line_uom_name, 
uom.uom_search_key as inout_line_uom_search_key, 

chg.charge_name as inout_line_charge_name,
chg.charge_description as inout_line_charge_description,

locator.warehouse_search_key as inout_line_warehouse_search_key,
locator.warehouse_name as inout_line_warehouse_name,
locator.warehouse_description as inout_line_warehouse_description,
locator.warehouse_active as inout_line_warehouse_active,
locator.warehouse_in_transit as inout_line_warehouse_in_transit,
locator.warehouse_prevent_negative_inventory as inout_line_warehouse_prevent_negative_inventory,
locator.warehouse_loc_address1 as inout_line_warehouse_loc_address1,
locator.warehouse_loc_address2 as inout_line_warehouse_loc_address2,
locator.warehouse_loc_address3 as inout_line_warehouse_loc_address3,
locator.warehouse_loc_address4 as inout_line_warehouse_loc_address4,
locator.warehouse_loc_city as inout_line_warehouse_loc_city,
locator.warehouse_loc_state as inout_line_warehouse_loc_state,
locator.warehouse_loc_country_code as inout_line_warehouse_loc_country_code,
locator.warehouse_loc_country_name as inout_line_warehouse_loc_country_name,
locator.locator_search_key as inout_line_locator_search_key,
locator.locator_x as inout_line_locator_x,
locator.locator_y as inout_line_locator_y,
locator.locator_z as inout_line_locator_z,
locator.locator_type as inout_line_locator_type

FROM m_inoutline iol
JOIN bi_inout io ON iol.m_inout_id=io.inout_id
LEFT JOIN bi_charge chg ON iol.c_charge_id=chg.charge_id
LEFT JOIN bi_order_line ol ON iol.c_orderline_id = ol.orderline_id
LEFT JOIN bi_product p ON iol.m_product_id = p.product_id
LEFT JOIN bi_uom uom ON iol.c_uom_id = uom.uom_id
JOIN bi_client c ON iol.ad_client_id = c.client_id
JOIN bi_org o ON iol.ad_org_id = o.org_id
LEFT JOIN bi_locator locator on iol.m_locator_id = locator.locator_id
;
SELECT 'inoutline.'||column_name||',' as inoutline FROM information_schema.columns WHERE  table_name   = 'bi_inout_line';
--SELECT COUNT(*) as inout_line_count FROM bi_inout_line;

CREATE VIEW bi_requisition AS
SELECT
c.*,
o.*,
reqn.m_requisition_id as requisition_id,
reqn.documentno AS requisition_documentno,
reqn.description AS requisition_description,
reqn.totallines AS requisition_total_lines,
reqn.daterequired AS requisition_date_required,
reqn.datedoc AS requisition_date_doc,
reqn.docstatus AS requisition_document_status,
reqn.created as requisition_created,
reqn.updated as requisition_updated,
dt.name as requisition_document_type,

wh.warehouse_search_key as requisition_warehouse_search_key,
wh.warehouse_name as requisition_warehouse_name,
wh.warehouse_description as requisition_warehouse_description,
wh.warehouse_active as requisition_warehouse_active,
wh.warehouse_in_transit as requisition_warehouse_in_transit,
wh.warehouse_prevent_negative_inventory as requisition_warehouse_prevent_negative_inventory,
wh.warehouse_loc_address1 as requisition_warehouse_loc_address1,
wh.warehouse_loc_address2 as requisition_warehouse_loc_address2,
wh.warehouse_loc_address3 as requisition_warehouse_loc_address3,
wh.warehouse_loc_address4 as requisition_warehouse_loc_address4,
wh.warehouse_loc_city as requisition_warehouse_loc_city,
wh.warehouse_loc_state as requisition_warehouse_loc_state,
wh.warehouse_loc_country_code as requisition_warehouse_loc_country_code,
wh.warehouse_loc_country_name as requisition_warehouse_loc_country_name,

u.user_search_key as requisition_user_search_key,
u.user_name as requisition_user_name,
u.user_description as requisition_user_description,
u.user_email as requisition_user_email,
u.user_phone as requisition_user_phone,
u.bpartner_search_key as requisition_bpartner_search_key,
u.bpartner_name as requisition_bpartner_name,
u.bpartner_name2 as requisition_bpartner_name2,
u.bpartner_created as requisition_bpartner_created,
u.bpartner_updated as requisition_bpartner_updated,
u.bpartner_customer as requisition_bpartner_customer,
u.bpartner_vendor as requisition_bpartner_vendor,
u.bpartner_employee as requisition_bpartner_employee,
u.bpartner_group_search_key as requisition_bpartner_group_search_key,
u.bpartner_group_name as requisition_bpartner_group_name,
u.bpartner_group_description as requisition_bpartner_group_description,
u.user_bploc_name as requisition_user_bploc_name,
u.user_bploc_created as requisition_user_bploc_created,
u.user_bploc_updated as requisition_user_bploc_updated,
u.user_bploc_address1 as requisition_user_bploc_address1,
u.user_bploc_address2 as requisition_user_bploc_address2,
u.user_bploc_address3 as requisition_user_bploc_address3,
u.user_bploc_address4 as requisition_user_bploc_address4,
u.user_bploc_city as requisition_user_bploc_city,
u.user_bploc_state as requisition_user_bploc_state,
u.user_bploc_country_code as requisition_user_bploc_country_code,
u.user_bploc_country_name as requisition_user_bploc_country_name

-- needs price list

FROM m_requisition reqn
JOIN bi_client c ON reqn.ad_client_id = c.client_id
JOIN bi_org o ON reqn.ad_org_id = o.org_id
JOIN c_doctype dt ON reqn.c_doctype_id = dt.c_doctype_id
JOIN bi_warehouse wh on reqn.m_warehouse_id = wh.warehouse_id
JOIN bi_user u on reqn.ad_user_id = u.user_id
;
SELECT 'requisition.'||column_name||',' as requisition FROM information_schema.columns WHERE  table_name   = 'bi_requisition';
--SELECT COUNT(*) as requisition_count FROM bi_requisition;

CREATE VIEW bi_requisition_line AS
SELECT

rl.m_requisitionline_id as requisitionline_id,

requisition.requisition_documentno,
requisition.requisition_description,
requisition.requisition_total_lines,
requisition.requisition_date_required,
requisition.requisition_date_doc,
requisition.requisition_document_status,
requisition.requisition_created,
requisition.requisition_updated,
requisition.requisition_document_type,
requisition.requisition_warehouse_search_key,
requisition.requisition_warehouse_name,
requisition.requisition_warehouse_description,
requisition.requisition_warehouse_active,
requisition.requisition_warehouse_in_transit,
requisition.requisition_warehouse_prevent_negative_inventory,
requisition.requisition_warehouse_loc_address1,
requisition.requisition_warehouse_loc_address2,
requisition.requisition_warehouse_loc_address3,
requisition.requisition_warehouse_loc_address4,
requisition.requisition_warehouse_loc_city,
requisition.requisition_warehouse_loc_state,
requisition.requisition_warehouse_loc_country_code,
requisition.requisition_warehouse_loc_country_name,
requisition.requisition_user_search_key,
requisition.requisition_user_name,
requisition.requisition_user_description,
requisition.requisition_user_email,
requisition.requisition_user_phone,
requisition.requisition_bpartner_search_key,
requisition.requisition_bpartner_name,
requisition.requisition_bpartner_name2,
requisition.requisition_bpartner_created,
requisition.requisition_bpartner_updated,
requisition.requisition_bpartner_customer,
requisition.requisition_bpartner_vendor,
requisition.requisition_bpartner_employee,
requisition.requisition_bpartner_group_search_key,
requisition.requisition_bpartner_group_name,
requisition.requisition_bpartner_group_description,

rl.line as requisition_line_lineno,
rl.description as requisition_line_description,
rl.qty as requisition_line_qty, 
rl.priceactual as requisition_line_price,
rl.linenetamt as requisition_line_linenetamt, 

p.product_search_key as reqiusition_line_product_search_key,
p.product_name as reqiusition_line_product_name,
p.product_description as reqiusition_line_product_description,
p.product_document_note as reqiusition_line_product_document_note,
p.product_category_name as reqiusition_line_product_category_name,

uom.uom_name as reqiusition_line_uom_name,
uom.uom_search_key as reqiusition_line_uom_search_key,

orderline.order_documentno,
orderline.order_grand_total,
orderline.order_document_status,
orderline.order_created,
orderline.order_updated,
orderline.order_ship_bpartner_search_key,
orderline.order_ship_bpartner_name,
orderline.order_ship_bpartner_name2,
orderline.order_ship_bpartner_created,
orderline.order_ship_bpartner_updated,
orderline.order_ship_bpartner_customer,
orderline.order_ship_bpartner_vendor,
orderline.order_ship_bpartner_employee,
orderline.order_ship_bpartner_group_search_key,
orderline.order_ship_bpartner_group_name,
orderline.order_ship_bpartner_group_description,
orderline.order_ship_bploc_name,
orderline.order_ship_bploc_address1,
orderline.order_ship_bploc_address2,
orderline.order_ship_bploc_address3,
orderline.order_ship_bploc_address4,
orderline.order_ship_bploc_city,
orderline.order_ship_bploc_state,
orderline.order_ship_bploc_country_code,
orderline.order_ship_bploc_country_name,
orderline.order_line_lineno,
orderline.order_line_qty_ordered,
orderline.order_line_qty_entered,
orderline.order_line_qty_invoiced,
orderline.order_line_qty_delivered,
orderline.order_line_description,
orderline.order_line_price_entered,
orderline.order_line_linenetamt,
orderline.order_line_created,
orderline.order_line_updated,

bp.bpartner_search_key as reqiusition_line_bpartner_search_key,
bp.bpartner_name as reqiusition_line_bpartner_name,
bp.bpartner_name2 as reqiusition_line_bpartner_name2,
bp.bpartner_created as reqiusition_line_bpartner_created,
bp.bpartner_customer as reqiusition_line_bpartner_customer,
bp.bpartner_vendor as reqiusition_line_bpartner_vendor,
bp.bpartner_employee as reqiusition_line_bpartner_employee,
bp.bpartner_group_search_key as requisition_line_bpartner_group_search_key,
bp.bpartner_group_name as requisition_line_bpartner_group_name,
bp.bpartner_group_description as requisition_line_bpartner_group_description

FROM m_requisitionline rl
JOIN bi_requisition requisition ON rl.m_requisition_id = requisition.requisition_id
LEFT JOIN bi_order_line orderline ON rl.c_orderline_id = orderline.orderline_id
LEFT JOIN bi_product p ON rl.m_product_id = p.product_id
LEFT JOIN bi_uom uom ON rl.c_uom_id = uom.uom_id
LEFT JOIN bi_bpartner bp ON rl.c_bpartner_id=bp.bpartner_id
;
SELECT 'requisitionline.'||column_name||',' as requisitionline FROM information_schema.columns WHERE  table_name   = 'bi_requisition_line';
--SELECT COUNT(*) as requisition_line_count FROM bi_requisition_line;

CREATE VIEW bi_request AS
SELECT 
c.*,
o.*,
req.r_request_id as request_id,
req.documentno as request_documentno,
reqtype.name AS request_type,
reqcat.name AS request_category,

reqstat.name AS request_status,
reqstat.isopen as request_status_open,
reqstat.isclosed as request_status_close,
reqstat.isfinalclose as request_status_final_close,

resol.name AS request_resolution,
req.priority as request_priority,
req.summary as request_summary,
req.datelastaction as request_date_last_action,
req.datenextaction as request_date_next_action,
req.lastresult as request_lastresult,
req.startdate as request_startdate,
req.closedate as request_closedate,
req.created as request_created,
req.updated as request_updated,

sr.name as request_user,
role.name as request_role,
bp.name as bpartner_name,
bp.value as bpartner_search_key,
ord.documentno as order_documentno,
p.value as product_search_key,
p.name as product_name,
proj.name as project_name,
proj.value as project_search_key,
inv.documentno as invoice_documentno,
pay.documentno as payment_documentno


FROM r_request req
JOIN r_requesttype reqtype ON req.r_requesttype_id = reqtype.r_requesttype_id
LEFT JOIN r_category reqcat ON req.r_category_id=reqcat.r_category_id
LEFT JOIN r_status reqstat ON req.r_status_id=reqstat.r_status_id
LEFT JOIN r_resolution resol ON req.r_resolution_id=resol.r_resolution_id
LEFT JOIN c_bpartner bp ON req.c_bpartner_id = bp.c_bpartner_id
JOIN bi_client c ON req.ad_client_id = c.client_id
JOIN bi_org o ON req.ad_org_id = o.org_id
LEFT JOIN c_order ord ON req.c_order_id=ord.c_order_id
LEFT JOIN m_product p ON req.m_product_id=p.m_product_id
LEFT JOIN ad_user sr on req.salesrep_id = sr.ad_user_id
LEFT JOIN ad_role role on req.ad_role_id = role.ad_role_id
LEFT JOIN c_project proj on req.c_project_id = proj.c_project_id
LEFT JOIN c_invoice inv on req.c_invoice_id = inv.c_invoice_id
LEFT JOIN c_payment pay on req.c_payment_id = pay.c_payment_id
;
SELECT 'request.'||column_name||',' as request FROM information_schema.columns WHERE  table_name   = 'bi_request';
--SELECT COUNT(*) as request_count FROM bi_request;

CREATE VIEW bi_production as 
SELECT
c.*,
o.*,
production.m_production_id as production_id,
production.documentno as production_documentno,
production.name as production_name,
production.description as production_description,
production.datepromised as production_date_promised,
production.movementdate as production_movement_date,
production.iscreated as production_records_created,
production.docstatus as production_document_status,
production.created as production_created,
production.updated as production_updated,

orderline.order_documentno,
orderline.order_grand_total,
orderline.order_sales_transaction,
orderline.order_document_status,
orderline.order_date_ordered,
orderline.order_document_type,
orderline.order_line_lineno,
orderline.order_line_qty_ordered,
orderline.order_line_qty_entered,
orderline.order_line_qty_invoiced,
orderline.order_line_qty_delivered,
orderline.order_line_description,
orderline.order_line_price_entered,
orderline.order_line_linenetamt,

prod.product_search_key as production_product_search_key,
prod.product_name as production_product_name,
prod.product_description as production_product_description,
prod.product_document_note as production_product_document_note,
prod.product_active as production_product_active,
prod.product_category_name as production_product_category_name,
prod.uom_name as production_uom_name,

bp.bpartner_search_key,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_group_search_key,
bp.bpartner_group_name,
bp.bpartner_group_description

from M_Production production
left join bi_product prod on production.m_product_id = prod.product_id
join bi_client c on production.ad_client_id = c.client_id
join bi_org o on production.ad_org_id = o.org_id
left join bi_order_line orderline on production.c_orderline_id = orderline.orderline_id
left join bi_bpartner bp on production.c_bpartner_id = bp.bpartner_id
;
SELECT 'production.'||column_name||',' as production FROM information_schema.columns WHERE  table_name   = 'bi_production';
--SELECT COUNT(*) as production_count FROM bi_production;


CREATE VIEW bi_production_line as
select 

production.production_documentno,
production.production_name,
production.production_description,
production.production_date_promised,
production.production_movement_date,
production.production_records_created,
production.production_document_status,
production.production_created,
production.production_updated,
production.order_documentno,
production.order_grand_total,
production.order_sales_transaction,
production.order_document_status,
production.order_date_ordered,
production.order_document_type,
production.order_line_lineno,
production.order_line_qty_ordered,
production.order_line_qty_entered,
production.order_line_qty_invoiced,
production.order_line_qty_delivered,
production.order_line_description,
production.order_line_price_entered,
production.order_line_linenetamt,
production.production_product_search_key,
production.production_product_name,
production.production_product_description,
production.production_product_document_note,
production.production_product_active,
production.production_product_category_name,
production.production_uom_name,
production.bpartner_search_key,
production.bpartner_name,
production.bpartner_name2,
production.bpartner_created,
production.bpartner_customer,
production.bpartner_vendor,

productionline.m_productionline_id as productionline_id,
productionline.line as produciton_line_lineno,
productionline.isendproduct as production_line_end_product,
productionline.isactive as production_line_active,
productionline.plannedqty as production_line_qty_planned,
productionline.qtyused as production_line_qty_used,
productionline.description as production_line_description,
productionline.created as production_line_created,
productionline.updated as production_line_updated,

locator.warehouse_search_key,
locator.warehouse_name,
locator.warehouse_description,
locator.warehouse_active,
locator.warehouse_in_transit,
locator.warehouse_prevent_negative_inventory,
locator.warehouse_loc_address1,
locator.warehouse_loc_address2,
locator.warehouse_loc_address3,
locator.warehouse_loc_address4,
locator.warehouse_loc_city,
locator.warehouse_loc_state,
locator.warehouse_loc_country_code,
locator.warehouse_loc_country_name,
locator.locator_id,
locator.locator_search_key,
locator.locator_x,
locator.locator_y,
locator.locator_z,
locator.locator_type,

prod.product_search_key as production_line_product_search_key,
prod.product_name as production_line_product_name,
prod.product_description as production_line_product_description,
prod.product_document_note as production_line_product_document_note,
prod.product_active as production_line_product_active,
prod.product_category_name as production_line_product_category_name,
prod.uom_name as production_line_uom_name

FROM m_productionline productionline
JOIN bi_production production on productionline.m_production_id = production.production_id
LEFT JOIN bi_product prod on productionline.m_product_id = prod.product_id
LEFT JOIN bi_locator locator on productionline.m_locator_id = locator.locator_id
;
SELECT 'productionline.'||column_name||',' as produtionline FROM information_schema.columns WHERE  table_name   = 'bi_production_line';
--SELECT COUNT(*) as production_line_count FROM bi_production_line;

-- show all SQL to update BI access
SELECT   CONCAT('GRANT SELECT ON adempiere.', TABLE_NAME, ' to biaccess;')
FROM     INFORMATION_SCHEMA.TABLES
WHERE    TABLE_SCHEMA = 'adempiere'
    AND TABLE_NAME LIKE 'bi_%'
;
