-- The purpose of this file is to help you restore a 10+ postgres export to a 9.6- instance.
-- Simply include this file with your restore script.
-- This file can be removed from the installation repository when postgresql 9.6 is no longer popular.
-- https://groups.google.com/forum/#!msg/idempiere/DeqZmqTU7Sk/__j-Nil5DwAJ

--------------------- No operator matches the given name and argument type(s). ---------------------
--------------------- You might need to add explicit type casts. ----------------------------------------

--
-- Name: +; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.+ (
PROCEDURE = adempiere.adddays,
LEFTARG = timestamp with time zone,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.+)
);


ALTER OPERATOR adempiere.+ (timestamp with time zone, numeric) OWNER TO adempiere;

--
-- Name: +; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.+ (
PROCEDURE = adempiere.adddays,
LEFTARG = interval,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.-)
);


ALTER OPERATOR adempiere.+ (interval, numeric) OWNER TO adempiere;

--
-- Name: -; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.- (
PROCEDURE = adempiere.subtractdays,
LEFTARG = timestamp with time zone,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.-)
);


ALTER OPERATOR adempiere.- (timestamp with time zone, numeric) OWNER TO adempiere;

--
-- Name: -; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.- (
PROCEDURE = adempiere.subtractdays,
LEFTARG = interval,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.-)
);


ALTER OPERATOR adempiere.- (interval, numeric) OWNER TO adempiere;

--------------------------------------------------------------

CREATE OR REPLACE VIEW adempiere.c_invoice_candidate_v
 AS
 SELECT o.ad_client_id,
    o.ad_org_id,
    o.c_bpartner_id,
    o.c_order_id,
    o.documentno,
    o.dateordered,
    o.c_doctype_id,
    sum((l.qtyordered - l.qtyinvoiced) * l.priceactual) AS totallines
   FROM c_order o
     JOIN c_orderline l ON o.c_order_id = l.c_order_id
     JOIN c_bpartner bp ON o.c_bpartner_id = bp.c_bpartner_id
     LEFT JOIN c_invoiceschedule si ON bp.c_invoiceschedule_id = si.c_invoiceschedule_id
  WHERE (o.docstatus = ANY (ARRAY['CO'::bpchar, 'CL'::bpchar, 'IP'::bpchar])) AND (o.c_doctype_id IN ( SELECT c_doctype.c_doctype_id
           FROM c_doctype
          WHERE c_doctype.docbasetype = 'SOO'::bpchar AND (c_doctype.docsubtypeso <> ALL (ARRAY['ON'::bpchar, 'OB'::bpchar, 'WR'::bpchar])))) AND l.qtyordered <> l.qtyinvoiced AND (o.invoicerule = 'I'::bpchar OR o.invoicerule = 'O'::bpchar AND NOT (EXISTS ( SELECT 1
           FROM c_orderline zz1
          WHERE zz1.c_order_id = o.c_order_id AND zz1.qtyordered <> zz1.qtydelivered)) OR o.invoicerule = 'D'::bpchar AND l.qtyinvoiced <> l.qtydelivered OR o.invoicerule = 'S'::bpchar AND bp.c_invoiceschedule_id IS NULL OR o.invoicerule = 'S'::bpchar AND bp.c_invoiceschedule_id IS NOT NULL AND (si.invoicefrequency IS NULL OR si.invoicefrequency = 'D'::bpchar OR si.invoicefrequency = 'W'::bpchar OR si.invoicefrequency = 'T'::bpchar AND (trunc(o.dateordered::timestamp with time zone) <= (firstof(getdate(), 'MM'::character varying)::timestamp with time zone + si.invoicedaycutoff - 1) AND trunc(getdate()) >= (firstof(o.dateordered::timestamp with time zone, 'MM'::character varying)::timestamp with time zone + si.invoiceday - 1) OR trunc(o.dateordered::timestamp with time zone) <= (firstof(getdate(), 'MM'::character varying)::timestamp with time zone + si.invoicedaycutoff + 14) AND trunc(getdate()) >= (firstof(o.dateordered::timestamp with time zone, 'MM'::character varying)::timestamp with time zone + si.invoiceday + 14)) OR si.invoicefrequency = 'M'::bpchar AND trunc(o.dateordered::timestamp with time zone) <= (firstof(getdate(), 'MM'::character varying)::timestamp with time zone + si.invoicedaycutoff - 1) AND trunc(getdate()) >= (firstof(o.dateordered::timestamp with time zone, 'MM'::character varying)::timestamp with time zone + si.invoiceday - 1)))
  GROUP BY o.ad_client_id, o.ad_org_id, o.c_bpartner_id, o.c_order_id, o.documentno, o.dateordered, o.c_doctype_id;

ALTER TABLE adempiere.c_invoice_candidate_v
    OWNER TO adempiere;
