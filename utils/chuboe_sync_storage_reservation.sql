--Created by Chuck Boecking
--details
	-- this script is designed for iDempiere. Use the similarly named script for ADempiere.
	-- create a backup of m_storagereservation
	-- review current table for accuracy
	-- delete all m_storagereservation records
	-- create new records for m_storagereservation for both qtyReserved and QtyOnOrder

--create a backup m_storagereservation
create table deleteme_TODAYSDATE_m_storagereservation as select * from m_storagereservation;

--test query - shows reserved QtyReserved and QtyOrdered accuracy 
	--used to test for accuracy first before resetting the table
	-- note - does not account for potentially missing records in m_storagereservation
select r.m_product_id, p.value as product_value, 
	r.m_warehouse_id, w.name as warehouse_name, 
	r.m_attributesetinstance_id, 
	coalesce(asi.serno, asi.lot, asi.description) as asi_description,
	r.issotrx, r.qty,
	(select sum(qtyreserved)
		from c_orderline ol
		join c_order o on ol.c_order_id = o.c_order_id
		where ol.m_product_id = r.m_product_id
			and ol.m_attributesetinstance_id = r.m_attributesetinstance_id
			and ol.m_warehouse_id = r.m_warehouse_id
			and o.issotrx = r.issotrx
	) as Order_QtyReserved
from m_storagereservation r
	join m_product p on r.m_product_id = p.m_product_id
	join m_warehouse w on r.m_warehouse_id = w.m_warehouse_id
	join m_attributesetinstance asi on r.m_attributesetinstance_id = asi.m_attributesetinstance_id
;

-- delete all records from m_storagereservation - to be created next
delete from m_storagereservation;

--create missing records for QtyReserved and QtyOnOrder
insert into m_storagereservation
(ad_client_id,
    ad_org_id,
    created,
    createdby,
    datelastinventory,
    isactive,
    issotrx,
    m_attributesetinstance_id,
    m_product_id,
    m_warehouse_id,
    qty,
    updated,
    updatedby,
    m_storagereservation_uu
) select o.ad_client_id,
		o.ad_org_id,
		now(),
		100,
		null,
		'Y',
		o.issotrx,
		ol.m_attributesetinstance_id,
		ol.m_product_id,
		ol.m_warehouse_id,
		sum(qtyreserved),
		now(),
		100,
		generate_uuid()
	from c_orderline ol
		join c_order o on ol.c_order_id = o.c_order_id
	where ol.qtyreserved <> 0
		and not exists (select * 
							from m_storagereservation xr 
							where xr.m_attributesetinstance_id = ol.m_attributesetinstance_id
								and xr.m_product_id = ol.m_product_id
								and xr.m_warehouse_id = ol.m_warehouse_id
								and xr.issotrx = o.issotrx
						)
	group by o.ad_client_id, o.ad_org_id,o.issotrx, ol.m_attributesetinstance_id, ol.m_product_id, ol.m_warehouse_id
;
