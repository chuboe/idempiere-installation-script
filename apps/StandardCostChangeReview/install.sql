--future cost change impact on inventory
create or replace view chuboe_future_cost_inventory as
select inv.name,
    inv.m_product_id,
    inv.ad_client_id,
    inv.ad_org_id,
    inv.m_attributesetinstance_id,
    inv.c_acctschema_id,
    inv.m_costtype_id,
    inv.currentcostprice,
    inv.futurecostprice,
    inv.c_currency_id,
    inv.costinglevel,
    inv.qtyonhand,
	inv.futurecostprice - inv.currentcostprice as costdelta
from chuboe_cost_per_product_per_org inv
where (costinglevel = 'C' 
	and ad_org_id = 0) or
	(costinglevel = 'O'
	and ad_org_id <> 0) or
	(costinglevel = 'B'
	and ad_org_id = 0)

--future cost change impact on booked but not shipped (scheduled) orders
create or replace view chuboe_future_cost_scheduled_order as
select ol.ad_org_id, ol.m_product_id, ol.qtyordered - ol.qtydelivered as qtyremaining, ol.priceentered, 
c.currentcostprice as currentcost, c.futurecostprice as futurecost, 
(c.futurecostprice - c.currentcostprice) as costdelta
from c_orderline ol
join c_order o on ol.c_order_id = o.c_order_id
join chuboe_cost_per_product_per_org c on ol.m_product_id = c.m_product_id and 
	ol.ad_org_id = c.ad_org_id and
	ol.m_attributesetinstance_id = c.m_attributesetinstance_id
where o.docstatus = 'CO' and o.issotrx = 'Y'
	and ol.qtyordered > ol.qtydelivered
;

--This view gives you the ability to find the cost for a given set of m_product_id, ad_org_id, m_attributesetinstance_id
--regardless of the costing method, costing level, schema, or cost type.
create or replace view chuboe_cost_per_product_per_org as
select tot.name, tot.m_product_id, tot.ad_client_id, tot.AD_Org_ID, tot.M_AttributeSetInstance_ID, tot.C_AcctSchema_ID, 
tot.M_CostType_ID, sum(tot.currentcostprice) as currentcostprice, sum(tot.futurecostprice) as futurecostprice, 
tot.c_currency_id, tot.costinglevel,
coalesce((select sum(s.qtyonhand) 
	from m_storageonhand s 
	join m_locator l on (s.m_locator_id = l.m_locator_id)
	where s.m_product_id = tot.m_product_id
		and s.M_AttributeSetInstance_ID = tot.M_AttributeSetInstance_ID
		and (tot.ad_org_id = l.ad_org_id)
),0) as qtyonhand
from 
(
	select p.name, c.m_product_id, p.ad_client_id, o.AD_Org_ID, c.M_AttributeSetInstance_ID, 
		c.C_AcctSchema_ID, c.M_CostType_ID,
		sum(c.currentcostprice) as currentcostprice, 
		sum(case when c.futurecostprice=0 then c.currentcostprice else c.futurecostprice end) as futurecostprice, 
		sch.c_currency_id, coalesce(pca.costinglevel, sch.costinglevel) as costinglevel
	from m_cost c
	join m_costelement ce on (c.M_CostElement_ID = ce.M_CostElement_ID)
	join m_product p on (c.m_product_id = p.m_product_id)
	join m_product_category pc on (p.m_product_category_id = pc.m_product_category_id)
	join m_product_category_acct pca on (pc.m_product_category_id = pca.m_product_category_id 
		and pca.C_AcctSchema_ID = c.C_AcctSchema_ID)
	join C_AcctSchema sch on (c.C_AcctSchema_ID = sch.C_AcctSchema_ID)
	join ad_org o on ((c.ad_org_id = 0 or c.ad_org_id = o.ad_org_id) -- join in all orgs (in case of ad_org_id = 0 to make future gross profit easier to calculate
		and o.isactive='Y' and o.issummary='N')
	where coalesce(pca.costingmethod, sch.costingmethod) = ce.costingmethod
	group by p.name, c.m_product_id, p.ad_client_id, o.AD_Org_ID, c.M_AttributeSetInstance_ID, 
		c.C_AcctSchema_ID, c.M_CostType_ID, sch.c_currency_id, coalesce(pca.costinglevel, sch.costinglevel)
) tot
group by tot.name, tot.m_product_id, tot.ad_client_id, tot.AD_Org_ID, tot.M_AttributeSetInstance_ID, 
	tot.C_AcctSchema_ID, tot.M_CostType_ID, tot.c_currency_id, tot.costinglevel
;