-- The purpose of this script is to help you create views that are easily used inside a BI or analytics tool.

----- Section 2 ----- Create the views needed to resolve keys into human readable words
DROP VIEW IF EXISTS bi_request;
DROP VIEW IF EXISTS bi_requisitionline;
DROP VIEW IF EXISTS bi_requisition;
DROP VIEW IF EXISTS bi_inoutline;
DROP VIEW IF EXISTS bi_inout;
DROP VIEW IF EXISTS bi_invoiceline;
DROP VIEW IF EXISTS bi_invoice;
DROP VIEW IF EXISTS bi_orderline;
DROP VIEW IF EXISTS bi_order;
DROP VIEW IF EXISTS bi_product;
DROP VIEW IF EXISTS bi_charge;
DROP VIEW IF EXISTS bi_bploc;
DROP VIEW IF EXISTS bi_bpartner;
DROP VIEW IF EXISTS bi_uom;
DROP VIEW IF EXISTS bi_org;
DROP VIEW IF EXISTS bi_client;

CREATE VIEW bi_client AS
SELECT c.name AS client_name,
    c.ad_client_id
   FROM ad_client c;
-- SELECT 'c.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_client';

CREATE VIEW bi_org AS
SELECT o.name AS org_name,
    o.value AS org_searchkey,
    o.ad_org_id,
    o.isactive AS org_active,
	o.ad_client_id
	FROM ad_org o
	WHERE o.issummary = 'N'::bpchar;
-- SELECT 'o.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_org';

CREATE VIEW bi_uom AS
SELECT uom.c_uom_id, 
	c.*,
	uom.name AS uom_name, 
	uom.uomsymbol AS uom_searchkey, 
	uom.isactive AS uom_active
FROM c_uom uom
	JOIN bi_client c on uom.ad_client_id=c.ad_client_id;
-- SELECT 'uom.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_uom';
	
CREATE VIEW bi_bpartner AS
SELECT
bp.c_bpartner_id,		
c.*,
bp.value AS bpartner_searchkey,
bp.name AS bpartner_name,
bp.name2 AS bpartner_name2,
bp.created AS bpartner_created,
bp.iscustomer AS bpartner_customer,
bp.isvendor AS bpartner_vendor,
bp.isemployee AS bpartner_employee
from c_bpartner bp
join bi_client c on bp.ad_client_id = c.ad_client_id
;
-- SELECT 'bp.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_bpartner';

CREATE VIEW bi_bploc AS
SELECT
bpl.c_bpartner_location_id,
bpl.c_bpartner_id,
c.*,
bpl.name AS bploc_name,
l.address1 AS bploc_address1,
l.address2 AS bploc_address2,
l.address3 AS bploc_address3,
l.address4 AS bploc_address4,
l.city AS bploc_city,
l.regionname AS bploc_state,
country.countrycode AS bploc_country_code,
country.name AS bploc_country_name
FROM c_bpartner_location bpl
JOIN bi_client c ON bpl.ad_client_id = c.ad_client_id
LEFT JOIN c_location l ON bpl.c_location_id = l.c_location_id
JOIN c_country country ON l.c_country_id = country.c_country_id
;
-- SELECT 'bploc.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_bploc';

CREATE VIEW bi_charge AS
SELECT 
	chg.c_charge_id,
	c.*,
	chg.name AS charge_name,
	chg.description AS charge_description,
	chg.isactive as charge_active
FROM c_charge chg
	JOIN bi_client c on chg.ad_client_id=c.ad_client_id;
-- SELECT 'chg.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_charge';

CREATE VIEW bi_product AS
SELECT
c.*,
p.m_product_id,
p.value as product_searchkey,
p.name as product_name,
p.description as product_description,
p.documentnote as product_document_note,
p.isactive as product_active,
pc.name as product_category_name,
uom.uom_name
from m_product p
join m_product_category pc on p.m_product_category_id = pc.m_product_category_id
join bi_uom uom on p.c_uom_id = uom.c_uom_id
join bi_client c on c.ad_client_id = p.ad_client_id
;
-- SELECT 'prod.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_product';

CREATE VIEW bi_order AS
SELECT
ord.c_order_id,
ord.documentno as Order_DocumentNo,
ord.grandtotal as Order_Grand_total,
ord.issotrx as Order_Sales_Transaction,
ord.docstatus as Order_document_status,
ord.dateordered as Order_date_ordered,
c.client_name,
o.ad_org_id, 
o.org_name,
o.org_searchkey,
o.org_active,
bp.c_bpartner_id,
bp.bpartner_searchkey,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,
bploc.c_bpartner_location_id,
bploc.bploc_name,
bploc.bploc_address1,
bploc.bploc_address2,
bploc.bploc_address3,
bploc.bploc_address4,
bploc.bploc_city,
bploc.bploc_state,
bploc.bploc_country_code,
bploc.bploc_country_name,
dt.name as doctype_name
from c_order ord
join bi_bpartner bp on ord.c_bpartner_id = bp.c_bpartner_id
join bi_bploc bploc on ord.c_bpartner_location_id = bploc.c_bpartner_location_id
join bi_client c on ord.ad_client_id = c.ad_client_id
join bi_org o on ord.ad_org_id = o.ad_org_id
join c_doctype dt on ord.c_doctype_id = dt.c_doctype_id
;
-- SELECT 'order.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_order';

CREATE VIEW bi_orderline AS
SELECT o.*,
	ol.c_orderline_id,
	ol.line as orderline_lineno,
	prod.m_product_id,
	prod.product_searchkey,
	prod.product_name,
	prod.product_description,
	prod.product_document_note,
	prod.product_category_name,
	uom.c_uom_id,
	uom.uom_name,
	uom.uom_searchkey,
	ol.qtyordered as orderline_qty_ordered,
	ol.qtyentered as orderline_qty_entered,
	ol.qtyinvoiced as orderline_qty_invoiced,
	ol.qtydelivered as orderline_qty_delivered,
	ol.description as orderline_description,
	ol.priceentered as orderline_price_entered,
	ol.linenetamt as orderline_linenetamt,
	chg.charge_name,
	chg.charge_description,
	ol.c_tax_id
	-- needs tax details here
FROM c_orderline ol
	JOIN bi_order o ON ol.c_order_id=o.c_order_id
	LEFT JOIN bi_product prod on ol.m_product_id = prod.m_product_id
	LEFT JOIN bi_charge chg ON ol.c_charge_id = chg.c_charge_id
	JOIN bi_uom uom on ol.c_uom_id=uom.c_uom_id
;
-- SELECT 'orderline.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_orderline';

CREATE VIEW bi_invoice AS
SELECT
inv.c_invoice_id,
inv.documentno as Invoice_DocumentNo,
inv.grandtotal AS Invoice_Grand_total,
inv.issotrx as Invoice_Sales_Transaction,
inv.docstatus as Invoice_document_status,
inv.dateinvoiced as Invoice_date_invoiced,
c.*,
o.ad_org_id,
o.org_name,
o.org_searchkey,
o.org_active,
bp.c_bpartner_id,
bp.bpartner_searchkey,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,
bpl.c_bpartner_location_id,
bpl.bploc_name,
bpl.bploc_address1,
bpl.bploc_address2,
bpl.bploc_address3,
bpl.bploc_address4,
bpl.bploc_city,
bpl.bploc_state,
bpl.bploc_country_code,
bpl.bploc_country_name,
dt.name as doctype_name
FROM c_invoice inv
JOIN bi_bpartner bp ON inv.c_bpartner_id = bp.c_bpartner_id
JOIN bi_bploc bpl ON inv.c_bpartner_location_id = bpl.c_bpartner_location_id
JOIN bi_client c ON inv.ad_client_id = c.ad_client_id
JOIN bi_org o ON inv.ad_org_id = o.ad_org_id
JOIN c_doctype dt ON inv.c_doctype_id = dt.c_doctype_id
;
-- SELECT 'invoice.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_invoice';

CREATE VIEW bi_invoiceline AS
SELECT i.*,
	il.c_invoiceline_id,
	il.line AS invoiceline_lineno,
	il.description as invoiceline_description,
	il.qtyinvoiced as invoiceline_qty_invoiced, 
	il.priceactual as invoiceline_price_actual,
	il.taxamt as invoiceline_tax_amt,
	il.linetotalamt as invoiceline_linetotalamt,
	il.linenetamt as invoiceline_linenetamt, 
	p.m_product_id,
	p.product_searchkey,
	p.product_name,
	p.product_description,
	p.product_document_note,
	p.product_category_name,
	chg.charge_name,
	chg.charge_description, 
	il.c_tax_id,
	-- heed tax details here
	uom.c_uom_id,
	uom.uom_name,
	uom.uom_searchkey
	-- orderline details go here
FROM c_invoiceline il 
	JOIN bi_invoice i ON il.c_invoice_id=i.c_invoice_id
	LEFT JOIN bi_orderline ol ON il.c_orderline_id = ol.c_orderline_id
	LEFT JOIN bi_product p ON il.m_product_id = p.m_product_id
	LEFT JOIN bi_uom uom ON il.c_uom_id=uom.c_uom_id
	LEFT JOIN bi_charge chg ON il.c_charge_id=chg.c_charge_id
;
-- SELECT 'invoiceline.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_invoiceline';

CREATE VIEW bi_inout AS
SELECT 
io.m_inout_id,
io.issotrx AS InOut_Sales_Transaction,
io.documentno AS InOut_DocumentNo,
io.docaction AS InOut_doc_action,
io.docstatus AS InOut_doc_status,
dt.name AS InOut_doctype_name,
io.description AS InOut_description,
io.dateordered AS InOut_date_ordered,
io.movementdate as inout_movement_date,
ord.order_DocumentNo,
ord.order_Grand_total,
ord.order_date_ordered,
inv.c_invoice_id,
inv.Invoice_DocumentNo,
inv.Invoice_Grand_total,
inv.Invoice_Sales_Transaction,
inv.Invoice_document_status,
inv.Invoice_date_invoiced,
bp.c_bpartner_id,
bp.bpartner_searchkey,
bp.bpartner_name,
bp.bpartner_name2,
bp.bpartner_created,
bp.bpartner_customer,
bp.bpartner_vendor,
bp.bpartner_employee,
bpl.c_bpartner_location_id,
bpl.bploc_name,
bpl.bploc_address1,
bpl.bploc_address2,
bpl.bploc_address3,
bpl.bploc_address4,
bpl.bploc_city,
bpl.bploc_state,
bpl.bploc_country_code,
bpl.bploc_country_name,
c.*,
o.ad_org_id,
o.org_name,
o.org_searchkey,
o.org_active
FROM m_inout io
JOIN bi_bpartner bp ON io.c_bpartner_id = bp.c_bpartner_id
JOIN bi_bploc bpl ON io.c_bpartner_location_id = bpl.c_bpartner_location_id
JOIN bi_client c ON io.ad_client_id = c.ad_client_id
JOIN bi_org o ON io.ad_org_id = o.ad_org_id
JOIN c_doctype dt ON io.c_doctype_id = dt.c_doctype_id
LEFT JOIN bi_order ord ON io.c_order_id=ord.c_order_id
LEFT JOIN bi_invoice inv ON io.c_invoice_id=inv.c_invoice_id
;
-- SELECT 'inout.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_inout';

CREATE VIEW bi_inoutline AS 
SELECT
iol.m_inoutline_id,
iol.line AS InOutline_lineno,
iol.description as inoutline_description,
iol.movementqty as inoutline_movement_qty,
io.m_inout_id,
io.InOut_Sales_Transaction,
io.InOut_DocumentNo,
io.InOut_doc_action,
io.InOut_doc_status,
io.InOut_doctype_name,
io.InOut_description,
io.InOut_date_ordered,
io.InOut_movement_date,
ol.c_orderline_id,
ol.orderline_lineno,
ol.orderline_qty_ordered,
ol.orderline_qty_invoiced,
ol.orderline_description,
ol.orderline_linenetamt,
p.m_product_id,
p.product_searchkey,
p.product_name,
p.product_description,
p.product_document_note,
p.product_active,
p.product_category_name,
uom.uom_name, 
uom.uom_searchkey, 
chg.c_charge_id,
chg.charge_name,
chg.charge_description,
c.*,
o.ad_org_id,
o.org_name,
o.org_searchkey,
o.org_active
FROM m_inoutline iol
JOIN bi_inout io ON iol.m_inout_id=io.m_inout_id
LEFT JOIN bi_charge chg ON iol.c_charge_id=chg.c_charge_id
LEFT JOIN bi_orderline ol ON iol.c_orderline_id = ol.c_orderline_id
LEFT JOIN bi_product p ON iol.m_product_id=p.m_product_id
LEFT JOIN bi_uom uom ON iol.c_uom_id=uom.c_uom_id
JOIN bi_client c ON iol.ad_client_id = c.ad_client_id
JOIN bi_org o ON iol.ad_org_id = o.ad_org_id
;
-- SELECT 'inoutline.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_inoutline';

CREATE VIEW bi_requisition AS
SELECT
reqn.m_requisition_id,
reqn.documentno AS requisition_documentno,
reqn.description AS requisition_description,
reqn.totallines AS requisition_total_lines,
reqn.daterequired AS requisition_date_required,
reqn.docstatus AS requisition_doc_status,
reqn.datedoc AS requisition_date_doc,
c.*,
o.ad_org_id,
o.org_name,
o.org_searchkey,
o.org_active,
dt.name AS doctype_name
FROM m_requisition reqn
JOIN bi_client c ON reqn.ad_client_id = c.ad_client_id
JOIN bi_org o ON reqn.ad_org_id = o.ad_org_id
JOIN c_doctype dt ON reqn.c_doctype_id = dt.c_doctype_id
;
-- SELECT 'requisition.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_requisition';

CREATE VIEW bi_requisitionline AS
SELECT reqn.*,
	rl.m_requisitionline_id,
	rl.line AS requisition_lineno,
	p.m_product_id,
	p.product_searchkey,
	p.product_name,
	p.product_description,
	p.product_document_note,
	p.product_category_name,
	rl.description,
	rl.qty, 
	rl.priceactual,
	rl.linenetamt, 
	uom.c_uom_id,
	uom.uom_name,
	uom.uom_searchkey,
	ol.c_orderline_id,
	ol.orderline_qty_ordered,
	ol.orderline_qty_invoiced,
	ol.orderline_description,
	ol.orderline_linenetamt,
	ol.c_tax_id,
	-- need tax data here
	bp.c_bpartner_id,
	bp.bpartner_searchkey,
	bp.bpartner_name,
	bp.bpartner_name2,
	bp.bpartner_created,
	bp.bpartner_customer,
	bp.bpartner_vendor,
	bp.bpartner_employee
FROM m_requisitionline rl
	JOIN bi_requisition reqn ON rl.m_requisition_id=reqn.m_requisition_id
	LEFT JOIN bi_orderline ol ON rl.c_orderline_id = ol.c_orderline_id
	LEFT JOIN bi_product p ON rl.m_product_id = p.m_product_id
	LEFT JOIN bi_uom uom ON rl.c_uom_id=uom.c_uom_id
	LEFT JOIN bi_bpartner bp ON rl.c_bpartner_id=bp.c_bpartner_id
;
-- SELECT 'requisitionline.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_requisitionline';

CREATE VIEW bi_request AS
SELECT req.r_request_id,
req.documentno as request_documentno,
reqtype.name AS requesttype_name,
reqcat.name AS category_name,
reqstat.name AS status_name,
resol.name AS resolution_name,
req.priority as request_priority,
req.summary as request_summary,
req.datelastaction as request_date_last_action,
req.lastresult as request_lastresult,
req.startdate as request_startdate,
req.closedate as request_closedate,
c.*,
o.ad_org_id,
o.org_name,
o.org_searchkey,
o.org_active
FROM r_request req
JOIN r_requesttype reqtype ON req.r_requesttype_id = reqtype.r_requesttype_id
LEFT JOIN r_category reqcat ON req.r_category_id=reqcat.r_category_id
LEFT JOIN r_status reqstat ON req.r_status_id=reqstat.r_status_id
LEFT JOIN r_resolution resol ON req.r_resolution_id=resol.r_resolution_id
LEFT JOIN bi_bpartner bp ON req.c_bpartner_id = bp.c_bpartner_id
JOIN bi_client c ON req.ad_client_id = c.ad_client_id
JOIN bi_org o ON req.ad_org_id = o.ad_org_id
LEFT JOIN bi_order ord ON req.c_order_id=ord.c_order_id
LEFT JOIN bi_product p ON req.m_product_id=p.m_product_id
;
-- SELECT 'request.'||column_name||',' FROM information_schema.columns WHERE  table_name   = 'bi_request';
