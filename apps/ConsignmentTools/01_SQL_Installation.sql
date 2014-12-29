CREATE VIEW chuboe_consign_cust_shipment AS
 SELECT io.ad_client_id,
    io.ad_org_id,
    io.created,
    io.createdby,
    io.updated,
    io.updatedby,
    io.c_bpartner_id,
    io.movementdate,
    iol.m_product_id,
    iol.movementqty,
    ( SELECT pu.c_bpartner_id
           FROM m_product_po pu
          WHERE ((pu.iscurrentvendor = 'Y'::bpchar) AND (pu.m_product_id = iol.m_product_id))
         LIMIT 1) AS po_bpartner_id,
    ( SELECT pp.pricestd
           FROM ((m_pricelist pl
             JOIN m_pricelist_version plv ON ((pl.m_pricelist_id = plv.m_pricelist_id)))
             JOIN m_productprice pp ON ((plv.m_pricelist_version_id = pp.m_pricelist_version_id)))
          WHERE (((plv.validfrom <= io.movementdate) AND (pp.m_product_id = iol.m_product_id)) AND ((pl.name)::text = 'Consignment'::text))
          ORDER BY plv.validfrom DESC
         LIMIT 1) AS priceconsign,
    (1000000)::numeric AS c_charge_id,
    (((((io.documentno)::text || ' - line: '::text) || iol.line) || ' Search Key: '::text) || (p.value)::text) AS description,
    io.m_warehouse_id,
    io.ad_client_id AS client_id,
    io.ad_org_id AS org_id,
    (1000000)::numeric AS charge_id,
    ( SELECT pu.c_bpartner_id
           FROM m_product_po pu
          WHERE ((pu.iscurrentvendor = 'Y'::bpchar) AND (pu.m_product_id = iol.m_product_id))
         LIMIT 1) AS bp_id
   FROM (((m_inout io
     JOIN m_inoutline iol ON ((io.m_inout_id = iol.m_inout_id)))
     JOIN m_warehouse wh ON ((io.m_warehouse_id = wh.m_warehouse_id)))
     JOIN m_product p ON ((iol.m_product_id = p.m_product_id)))
  WHERE ((io.issotrx = 'Y'::bpchar) AND ((wh.name)::text = 'Consignment'::text));