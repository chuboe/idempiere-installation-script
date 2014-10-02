-- Disclaimer - The quality of this script is not a the level of my normal script. It was posted at the request of someone. I figured it is better to post something to act as a guide than to post nothing at all.
-- This script is designed to ADempiere's M_Storage QtyReserved and QtyOnOrder. This script is significantly more complex than iDempiere's sync.
-- This script accounts for Manufacturing Orders,  Distribution Orders and Sales/Purchase Order's impact on M_Storage.
-- This script was created for an ADempiere isntance that has been modified. It may need to work to get it to work with stock ADempiere. Please let me know of any needed changes.
-- Each Product at each WH must have an m_storage record for the default locator with a 0 ASI since this is the record being matched against for the update.
-- Note: DOs and IM's are customized heavily:  Moved columns from Header to Lines, have redundancy on DO line : WH and Locator FROM/TO

See the Problem:  Show mismatched Storage OnOrder and Doc ONORDER:
SELECT * 
FROM 
-- Query "x" starts here
(
select mp.value,  tot.m_product_id, tot.name, tot.m_locator_id, 1000000::numeric AS ad_client_id,  mp.producttype,
--Subselect to sum qtyOrdered from m_Storage - I think this is only here so we can run below without UPDATE above and compare what our DOCs say vs. M_Storage
(SELECT 
SUM (qtyOrdered) 
FROM m_storage ms
INNER JOIN M_Locator sl ON (ms.M_Locator_ID=sl.M_Locator_ID)
INNER JOIN M_Warehouse sw ON (sl.M_Warehouse_ID=sw.M_Warehouse_ID)
WHERE ms.m_product_id=mp.m_product_id
AND sw.m_warehouse_id=tot.m_warehouse_id
AND ms.ad_org_id<>55
--AND ms.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID
Group by sw.name) AS storage_onOrder,

SUM(tot.qtyonorder) AS document_OnOrder, tot.M_AttributeSetInstance_ID, tot.ad_org_id

 FROM (
 --subquery "tot" starts here
-- All DO lines: *** DISTRIBUTION ORDERS****   On Order = dol.qtyordered-dol.qtydelivered -- don't use OO/Reserve field as it is often wrong 
SELECT  dol.ad_org_id, dol.m_product_id as m_product_id, (dol.qtyordered-dol.qtydelivered) AS qtyonorder, w.name, w.m_warehouse_id, 
CASE 
	WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID,  0::numeric AS M_AttributeSetInstance_ID  

FROM DD_OrderLine dol
INNER JOIN DD_Order ddo ON (ddo.DD_Order_ID=dol.DD_Order_ID) 
INNER JOIN M_Locator l ON (dol.M_Locatorto_ID=l.M_Locator_ID)
 -- NOTE: LocatorTO ... not sure if like this out of the box ... maybe uses WH on the header
INNER JOIN M_Warehouse w ON (l.M_Warehouse_ID=w.M_Warehouse_ID)
  
WHERE ddo.docstatus IN('IP','CO')
AND dol.ad_org_id<>55
--Verify inprogress DO's have modified M_storage
-- AND ol.qtyordered<>0

UNION ALL -- MO FG --qtyordered  ****MANUFACTURING ORDERS ***** 

SELECT ppo.ad_org_id, ppo.m_product_id as m_product_id, ppo.qtyreserved AS qtyonorder -- verify reserve is really on order for the header. Not a real issue for us as we are NOT doing partial ORIs
,  w.name, w.m_warehouse_id,

CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID

FROM PP_Order ppo
INNER JOIN M_Warehouse w ON (ppo.M_Warehouse_ID=w.M_Warehouse_ID)
WHERE ppo.QtyReserved<>0 --AND ppo.docstatus IN('IP','CO') -- Doc status non issue: Drafted has no qtyReserve ... CL is a good state too
AND ppo.ad_org_id<>55			

UNION ALL    --*******   PURCHASE ORDERS  ***** 

SELECT ol.ad_org_id, ol.m_product_id as m_product_id, ol.qtyreserved AS qtyonorder,  w.name, w.m_warehouse_id,
CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID 
FROM C_Order o
 INNER JOIN C_OrderLine ol ON (o.C_Order_ID=ol.C_Order_ID)
 INNER JOIN M_Warehouse w ON (ol.M_Warehouse_ID=w.M_Warehouse_ID)
--INNER JOIN C_BPartner bp  ON (o.C_BPartner_ID=bp.C_BPartner_ID)
WHERE ol.QtyReserved<>0  AND o.issotrx='N' AND o.docstatus IN('IP','CO') 
AND o.ad_org_id<>55

) tot

left join m_product mp on (mp.m_product_id=tot.m_product_id)

group by  mp.producttype, tot.m_warehouse_id, tot.m_product_id, mp.value, mp.m_product_id,  tot.name, tot.m_locator_id, tot.M_AttributeSetInstance_ID, tot.ad_org_id --, tot.M_AttributeSetInstance_ID
order by tot.m_warehouse_id) 
x
WHERE x.producttype='I'
AND x.storage_onOrder<> x.document_OnOrder
--WHERE x.value='ROP275R037'
--GROUP BY x.value, x.m_product_id, x.name, x.m_warehouse_id
--ORDER BY name asc, value
--END
-- See the Problem:  Show mismatched storage RESERVE and Doc RESERVE:
SELECT *
  FROM 
--Query "x" starts here
(
select mp.value,  tot.m_product_id, tot.name, tot.m_locator_id, 1000000::numeric AS ad_client_id, mp.producttype,
--Subselect to sum qtyReserved from m_Storage - I think this is only here so we can run this without UPDATE above and compare what our DOCs say vs. M_Storage
(
SELECT 
SUM (qtyreserved) 
FROM m_storage ms
INNER JOIN M_Locator sl ON (ms.M_Locator_ID=sl.M_Locator_ID)
INNER JOIN M_Warehouse sw ON (sl.M_Warehouse_ID=sw.M_Warehouse_ID)
WHERE ms.m_product_id=mp.m_product_id
AND sw.m_warehouse_id=tot.m_warehouse_id
AND ms.ad_org_id<>55 -- don't care about this ORG
--AND ms.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID -- Don't care about ASI 
Group by sw.name
)   AS storage_reserve,

SUM(tot.qtyreserved) AS document_reserve, tot.M_AttributeSetInstance_ID, tot.ad_org_id

 FROM 
 (
 --subquery "tot" starts here
-- All DO lines: *** DISTRIBUTION ORDERS****  Reserve for a doline = dol.qtyordered-dol.qtyintransit-dol.qtydelivered - don't use OO/Reserve field as it is often wrong 
    SELECT  dol.ad_org_id, dol.m_product_id as m_product_id, (dol.qtyordered-dol.qtyintransit-dol.qtydelivered) AS qtyreserved, w.name, w.m_warehouse_id, 
-- below, we return the default locator for each of our warehouses and a 0 ASI so that reserve updated against the default locator w/0 ASI
CASE 
	WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID,  0::numeric AS M_AttributeSetInstance_ID 

FROM DD_OrderLine dol
INNER JOIN DD_Order ddo ON (ddo.DD_Order_ID=dol.DD_Order_ID) 
INNER JOIN M_Locator l ON (dol.M_Locator_ID=l.M_Locator_ID)
INNER JOIN M_Warehouse w ON (l.M_Warehouse_ID=w.M_Warehouse_ID)
  
WHERE ddo.docstatus IN('IP','CO')  -- Only consider relevant DO statuses
AND dol.ad_org_id<>55 -- ignore this ORG

UNION ALL        --****  MANUFACTURING COMPONENTS *****  NOTE: Components on PP_Order_BOMLine, NOT HEADER (used for OnOrder)

SELECT ol.ad_org_id, ol.m_product_id as m_product_id, ol.qtyreserved,  w.name, w.m_warehouse_id, 
-- below, we return the default locator for each of our warehouses and a 0 ASI so that reserve updated against the default locator w/0 ASI
CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID

FROM PP_Order ppo

INNER JOIN PP_Order_BOMLine ol ON (ppo.PP_Order_ID=ol.PP_Order_ID)
INNER JOIN M_Warehouse w ON (ppo.M_Warehouse_ID=w.M_Warehouse_ID)

WHERE ppo.docstatus in ('IP','CO') -- MOs reserve when IP and CO.  Our Reserve override model updates the qtyreserved field so even when there is override, this should be right
AND ppo.ad_org_id<>55

UNION ALL      -- ********  SALES ORDERS *****   
-- be sure we cover Blanket POs ***
-- IP doesn't reserve always 

SELECT ol.ad_org_id, ol.m_product_id as m_product_id, ol.qtyreserved AS qtyreserved,  w.name, w.m_warehouse_id,

CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID--, ol.M_AttributeSetInstance_ID--,sum(ol.QtyReserved)  as QtyReserved
FROM C_Order o
 INNER JOIN C_OrderLine ol ON (o.C_Order_ID=ol.C_Order_ID)
 INNER JOIN C_DocType dt ON (o.C_DocType_ID=dt.C_DocType_ID)
 INNER JOIN M_Warehouse w ON (ol.M_Warehouse_ID=w.M_Warehouse_ID)
WHERE o.issotrx='Y' 
   AND dt.docbasetype='SOO' AND dt.docsubtypeso IN ('SO','OB')  -- All SO's and BKT SOs (OB) that create reserve 
   AND o.docstatus IN ('IP','CO') -- Although IP SO's don't create reserve due to our code change, Completed SO's reopened to IP still do.
   AND ol.QtyReserved<>0  -- speed things up
   AND o.ad_org_id<>55

) tot

left join m_product mp on (mp.m_product_id=tot.m_product_id)
group by mp.producttype, tot.m_warehouse_id, tot.m_product_id, mp.value, mp.m_product_id,  tot.name, tot.m_locator_id, tot.M_AttributeSetInstance_ID, tot.ad_org_id
order by tot.m_warehouse_id )
x
WHERE x.producttype='I' -- do only ITEM type products, not services
AND x.storage_reserve<> x.document_reserve
--WHERE x.value='ROP275R037'
--GROUP BY x.value, x.m_product_id, x.name, x.m_warehouse_id
--ORDER BY name asc, value

FIX THE PROBLEM - Global 

-- Backup m_storage
CREATE TABLE m_storage_backupfeb242014 AS SELECT * FROM m_storage
RESERVE
-- ZERO out Reserve 

UPDATE m_storage SET qtyreserved = 0

-- UPDATE Reserve based on open Documents 

UPDATE m_storage SET qtyreserved=diff.document_reserve

FROM 
(  -- discrepant qtyordered script here.
SELECT *
  FROM 
--Query "x" starts here
(
select mp.value,  tot.m_product_id, tot.name, tot.m_locator_id, 1000000::numeric AS ad_client_id, mp.producttype,
--Subselect to sum qtyReserved from m_Storage - I think this is only here so we can run this without UPDATE above and compare what our DOCs say vs. M_Storage
(
SELECT 
SUM (qtyreserved) 
FROM m_storage ms
INNER JOIN M_Locator sl ON (ms.M_Locator_ID=sl.M_Locator_ID)
INNER JOIN M_Warehouse sw ON (sl.M_Warehouse_ID=sw.M_Warehouse_ID)
WHERE ms.m_product_id=mp.m_product_id
AND sw.m_warehouse_id=tot.m_warehouse_id
AND ms.ad_org_id<>55 -- don't care about this ORG
--AND ms.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID -- Don't care about ASI 
Group by sw.name
)   AS storage_reserve,

SUM(tot.qtyreserved) AS document_reserve, tot.M_AttributeSetInstance_ID, tot.ad_org_id

 FROM 
 (
 --subquery "tot" starts here
-- All DO lines: *** DISTRIBUTION ORDERS****  Reserve for a doline = dol.qtyordered-dol.qtyintransit-dol.qtydelivered - don't use OO/Reserve field as it is often wrong 
    SELECT  dol.ad_org_id, dol.m_product_id as m_product_id, (dol.qtyordered-dol.qtyintransit-dol.qtydelivered) AS qtyreserved, w.name, w.m_warehouse_id, 
-- below, we return the default locator for each of our warehouses and a 0 ASI so that reserve updated against the default locator w/0 ASI
CASE 
	WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID,  0::numeric AS M_AttributeSetInstance_ID 

FROM DD_OrderLine dol
INNER JOIN DD_Order ddo ON (ddo.DD_Order_ID=dol.DD_Order_ID) 
INNER JOIN M_Locator l ON (dol.M_Locator_ID=l.M_Locator_ID)
INNER JOIN M_Warehouse w ON (l.M_Warehouse_ID=w.M_Warehouse_ID)
  
WHERE ddo.docstatus IN('IP','CO')  -- Only consider relevant DO statuses
AND dol.ad_org_id<>55 -- ignore this ORG

UNION ALL        --****  MANUFACTURING COMPONENTS *****  NOTE: Components on PP_Order_BOMLine, NOT HEADER (used for OnOrder)

SELECT ol.ad_org_id, ol.m_product_id as m_product_id, ol.qtyreserved,  w.name, w.m_warehouse_id, 
-- below, we return the default locator for each of our warehouses and a 0 ASI so that reserve updated against the default locator w/0 ASI
CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID

FROM PP_Order ppo

INNER JOIN PP_Order_BOMLine ol ON (ppo.PP_Order_ID=ol.PP_Order_ID)
INNER JOIN M_Warehouse w ON (ppo.M_Warehouse_ID=w.M_Warehouse_ID)

WHERE ppo.docstatus in ('IP','CO') -- MOs reserve when IP and CO.  Our Reserve override model updates the qtyreserved field so even when there is override, this should be right
AND ppo.ad_org_id<>55

UNION ALL      -- ********  SALES ORDERS *****   
-- be sure we cover Blanket POs ***
-- IP doesn't reserve always 

SELECT ol.ad_org_id, ol.m_product_id as m_product_id, ol.qtyreserved AS qtyreserved,  w.name, w.m_warehouse_id,

CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID--, ol.M_AttributeSetInstance_ID--,sum(ol.QtyReserved)  as QtyReserved
FROM C_Order o
 INNER JOIN C_OrderLine ol ON (o.C_Order_ID=ol.C_Order_ID)
 INNER JOIN C_DocType dt ON (o.C_DocType_ID=dt.C_DocType_ID)
 INNER JOIN M_Warehouse w ON (ol.M_Warehouse_ID=w.M_Warehouse_ID)
WHERE o.issotrx='Y' 
   AND dt.docbasetype='SOO' AND dt.docsubtypeso IN ('SO','OB')  -- All SO's and BKT SOs (OB) that create reserve 
   AND o.docstatus IN ('IP','CO') -- Although IP SO's don't create reserve due to our code change, Completed SO's reopened to IP still do.
   AND ol.QtyReserved<>0  -- speed things up
   AND o.ad_org_id<>55

) tot

left join m_product mp on (mp.m_product_id=tot.m_product_id)
group by mp.producttype, tot.m_warehouse_id, tot.m_product_id, mp.value, mp.m_product_id,  tot.name, tot.m_locator_id, tot.M_AttributeSetInstance_ID, tot.ad_org_id
order by tot.m_warehouse_id )
x
WHERE x.producttype='I' -- do only ITEM type products, not services
 )  diff

where 
-- match on Client, Org, Product, Locator, ASI
m_storage.m_product_id=diff.m_product_id
and m_storage.m_locator_id=diff.m_locator_id
and m_storage.m_attributesetinstance_id=diff.M_AttributeSetInstance_ID
AND m_storage.ad_org_id = diff.ad_org_id
AND m_storage.ad_client_id=diff.ad_client_id
ON ORDER
-- Zero out OnOrder 

UPDATE m_storage SET qtyordered = 0

-- Update 

UPDATE m_storage SET qtyordered=diff.document_OnOrder
FROM 
(
--Highlight from here to ##1## to see comparison 
SELECT * 
FROM 
-- Query "x" starts here
(
select mp.value,  tot.m_product_id, tot.name, tot.m_locator_id, 1000000::numeric AS ad_client_id,  mp.producttype,
--Subselect to sum qtyOrdered from m_Storage - I think this is only here so we can run below without UPDATE above and compare what our DOCs say vs. M_Storage
(SELECT 
SUM (qtyOrdered) 
FROM m_storage ms
INNER JOIN M_Locator sl ON (ms.M_Locator_ID=sl.M_Locator_ID)
INNER JOIN M_Warehouse sw ON (sl.M_Warehouse_ID=sw.M_Warehouse_ID)
WHERE ms.m_product_id=mp.m_product_id
AND sw.m_warehouse_id=tot.m_warehouse_id
AND ms.ad_org_id<>55
--AND ms.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID=tot.M_AttributeSetInstance_ID
Group by sw.name) AS storage_onOrder,

SUM(tot.qtyonorder) AS document_OnOrder, tot.M_AttributeSetInstance_ID, tot.ad_org_id

 FROM (
 --subquery "tot" starts here
-- All DO lines: *** DISTRIBUTION ORDERS****   On Order = dol.qtyordered-dol.qtydelivered -- don't use OO/Reserve field as it is often wrong 
SELECT  dol.ad_org_id, dol.m_product_id as m_product_id, (dol.qtyordered-dol.qtydelivered) AS qtyonorder, w.name, w.m_warehouse_id, 
CASE 
	WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID,  0::numeric AS M_AttributeSetInstance_ID  

FROM DD_OrderLine dol
INNER JOIN DD_Order ddo ON (ddo.DD_Order_ID=dol.DD_Order_ID) 
INNER JOIN M_Locator l ON (dol.M_Locatorto_ID=l.M_Locator_ID)
 -- NOTE: LocatorTO ... not sure if like this out of the box ... maybe uses WH on the header
INNER JOIN M_Warehouse w ON (l.M_Warehouse_ID=w.M_Warehouse_ID)
  
WHERE ddo.docstatus IN('IP','CO')
AND dol.ad_org_id<>55
--Verify inprogress DO's have modified M_storage
-- AND ol.qtyordered<>0

UNION ALL -- MO FG --qtyordered  ****MANUFACTURING ORDERS ***** 

SELECT ppo.ad_org_id, ppo.m_product_id as m_product_id, ppo.qtyreserved AS qtyonorder -- verify reserve is really on order for the header. Not a real issue for us as we are NOT doing partial ORIs
,  w.name, w.m_warehouse_id,

CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID

FROM PP_Order ppo
INNER JOIN M_Warehouse w ON (ppo.M_Warehouse_ID=w.M_Warehouse_ID)
WHERE ppo.QtyReserved<>0 --AND ppo.docstatus IN('IP','CO') -- Doc status non issue: Drafted has no qtyReserve ... CL is a good state too
AND ppo.ad_org_id<>55			

UNION ALL    --*******   PURCHASE ORDERS  ***** 

SELECT ol.ad_org_id, ol.m_product_id as m_product_id, ol.qtyreserved AS qtyonorder,  w.name, w.m_warehouse_id,
CASE WHEN w.m_warehouse_ID = 1000001 THEN 1000101::numeric
	WHEN w.m_warehouse_ID = 1000002 THEN 1002789::numeric
	WHEN w.m_warehouse_ID = 1000003 THEN 1002785::numeric
	WHEN w.m_warehouse_ID = 1000004 THEN 1002794::numeric
	WHEN w.m_warehouse_ID = 1000015 THEN 1000014::numeric
	WHEN w.M_Warehouse_ID = 1000010 THEN 1002791::numeric
	WHEN w.M_Warehouse_ID=1000024 THEN 1200011::numeric
	WHEN w.M_Warehouse_ID=1000016 THEN 1002799::numeric
END AS M_Locator_ID, 0::numeric AS M_AttributeSetInstance_ID 
FROM C_Order o
 INNER JOIN C_OrderLine ol ON (o.C_Order_ID=ol.C_Order_ID)
 INNER JOIN M_Warehouse w ON (ol.M_Warehouse_ID=w.M_Warehouse_ID)
--INNER JOIN C_BPartner bp  ON (o.C_BPartner_ID=bp.C_BPartner_ID)
WHERE ol.QtyReserved<>0  AND o.issotrx='N' AND o.docstatus IN('IP','CO') 
AND o.ad_org_id<>55

) tot

left join m_product mp on (mp.m_product_id=tot.m_product_id)

group by  mp.producttype, tot.m_warehouse_id, tot.m_product_id, mp.value, mp.m_product_id,  tot.name, tot.m_locator_id, tot.M_AttributeSetInstance_ID, tot.ad_org_id --, tot.M_AttributeSetInstance_ID
order by tot.m_warehouse_id) 
x
WHERE x.producttype='I'
--AND x.storage_onOrder<> x.document_OnOrder
--WHERE x.value='ROP275R037'
--GROUP BY x.value, x.m_product_id, x.name, x.m_warehouse_id
--ORDER BY name asc, value

--Highlight ENDS here FROM ##1## to see comparison; uncomment 5 lines up for diffs only

) diff

where 
m_storage.m_product_id=diff.m_product_id
and m_storage.m_locator_id=diff.m_locator_id
and m_storage.m_attributesetinstance_id=diff.M_AttributeSetInstance_ID
AND m_storage.ad_org_id = diff.ad_org_id
AND m_storage.ad_client_id=diff.ad_client_id
--and diff.m_product_id=7015642 -- updated good