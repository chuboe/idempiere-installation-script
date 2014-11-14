CREATE VIEW chuboe_rv_storage AS
 SELECT s.ad_client_id,
    s.ad_org_id,
    s.m_product_id,
    s.value,
    s.name,
    s.description,
    s.upc,
    s.sku,
    s.c_uom_id,
    s.m_product_category_id,
    s.m_warehouse_id,
    sum(s.qtyonhand) AS qtyonhand,
    s.m_attributesetinstance_id,
    s.m_attributeset_id,
    s.serno,
    s.lot,
    COALESCE(( SELECT sum(ol.qtyordered) AS count
           FROM (c_orderline ol
             JOIN c_order o ON ((ol.c_order_id = o.c_order_id)))
          WHERE (((((ol.m_product_id = s.m_product_id) AND (o.issotrx = 'Y'::bpchar)) AND (ol.m_attributesetinstance_id = s.m_attributesetinstance_id)) AND (o.docstatus = ANY (ARRAY['CO'::bpchar, 'CL'::bpchar]))) AND (o.datepromised > (now() - (180)::numeric)))), (0)::numeric) AS orderqty_so,
    COALESCE(( SELECT sum(ol.qtyordered) AS count
           FROM (c_orderline ol
             JOIN c_order o ON ((ol.c_order_id = o.c_order_id)))
          WHERE (((((ol.m_product_id = s.m_product_id) AND (o.issotrx = 'N'::bpchar)) AND (ol.m_attributesetinstance_id = s.m_attributesetinstance_id)) AND (o.docstatus = ANY (ARRAY['CO'::bpchar, 'CL'::bpchar]))) AND (o.datepromised > (now() - (180)::numeric)))), (0)::numeric) AS orderqty_po,
    COALESCE(( SELECT sum(r.level_min) AS sum
           FROM m_replenish r
          WHERE (((r.m_product_id = s.m_product_id) AND (r.isactive = 'Y'::bpchar)) AND (s.m_warehouse_id = r.m_warehouse_id))), (0)::numeric) AS replenishlevel,
    (100)::numeric AS createdby,
    (100)::numeric AS updatedby,
    date_trunc('day'::text, now()) AS created,
    date_trunc('day'::text, now()) AS updated
   FROM rv_storage s
  WHERE (s.qtyonhand <> (0)::numeric)
  GROUP BY s.ad_client_id, s.ad_org_id, s.m_product_id, s.value, s.name, s.description, s.upc, s.sku, s.c_uom_id, s.m_product_category_id, s.m_warehouse_id, s.m_attributesetinstance_id, s.m_attributeset_id, s.serno, s.lot;