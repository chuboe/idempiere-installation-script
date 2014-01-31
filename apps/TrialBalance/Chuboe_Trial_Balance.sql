------------------------------
-- Function to determine the beginning of a fiscal year
------------------------------
CREATE OR REPLACE FUNCTION ChuBoe_fiscalstartdate(p_calendar_id numeric, p_acctdate timestamp without time zone)
  RETURNS timestamp without time zone AS
$BODY$DECLARE
	v_year_id		numeric :=0;
	v_startDate		timestamp without time zone := null;
BEGIN

SELECT min(startdate) into v_startDate
FROM C_Period
where C_Year_ID in
(
SELECT p.c_year_id
FROM C_Period p
JOIN C_Year y on (p.c_year_id = y.c_year_id)
WHERE y.c_calendar_id = p_calendar_id
 AND p_acctdate BETWEEN TRUNC(p.StartDate) AND TRUNC(p.EndDate)
 AND p.IsActive='Y' 
 AND p.PeriodType='S'
)
;

RETURN	v_startDate;
END;	$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ChuBoe_fiscalstartdate(numeric, timestamp without time zone) OWNER TO adempiere;

------------------------------
-- view to use the parameters from the trial balance header to pull the approprate Fact_Acct (GL) records.
------------------------------

CREATE VIEW ChuBoe_trialbalance_detail_v AS
    SELECT fa.fact_acct_id, fa.ad_client_id, fa.ad_org_id, fa.isactive, fa.created, fa.createdby, fa.updated, fa.updatedby, fa.c_acctschema_id, fa.account_id, fa.datetrx, fa.dateacct, fa.c_period_id, fa.ad_table_id, fa.record_id, fa.line_id, fa.gl_category_id, fa.gl_budget_id, fa.c_tax_id, fa.m_locator_id, fa.postingtype, fa.c_currency_id, fa.amtsourcedr, fa.amtsourcecr, fa.amtacctdr, fa.amtacctcr, fa.c_uom_id, fa.qty, fa.m_product_id, fa.c_bpartner_id, fa.ad_orgtrx_id, fa.c_locfrom_id, fa.c_locto_id, fa.c_salesregion_id, fa.c_project_id, fa.c_campaign_id, fa.c_activity_id, fa.user1_id, fa.user2_id, fa.description, fa.a_asset_id, fa.c_subacct_id, fa.userelement1_id, fa.userelement2_id, fa.c_projectphase_id, fa.c_projecttask_id, h.ChuBoe_trialbalance_hdr_id, fa.fact_acct_id AS ChuBoe_trialbalance_detail_v_id, h.created AS hdr_created, h.createdby AS hdr_createdby, h.updated AS hdr_updated, h.updatedby AS hdr_updatedby, ev.accounttype FROM ((((fact_acct fa JOIN c_elementvalue ev ON ((fa.account_id = ev.c_elementvalue_id))) JOIN ChuBoe_trialbalance_hdr h ON ((fa.ad_client_id = h.ad_client_id))) LEFT JOIN c_elementvalue acctfrom ON ((h.accountfrom_id = acctfrom.c_elementvalue_id))) LEFT JOIN c_elementvalue acctto ON ((h.accountto_id = acctto.c_elementvalue_id))) WHERE ((((((fa.dateacct >= CASE WHEN (ev.accounttype = ANY (ARRAY['A'::bpchar, 'L'::bpchar, 'O'::bpchar])) THEN fa.dateacct ELSE ChuBoe_fiscalstartdate(h.c_calendar_id, h.dateacctto) END) AND (fa.ad_org_id = CASE WHEN (h.ref_org_id IS NOT NULL) THEN h.ref_org_id ELSE fa.ad_org_id END)) AND ((ev.value)::text >= (CASE WHEN (h.accountfrom_id IS NOT NULL) THEN acctfrom.value ELSE ev.value END)::text)) AND ((ev.value)::text <= (CASE WHEN (h.accountto_id IS NOT NULL) THEN acctto.value ELSE ev.value END)::text)) AND (fa.dateacct >= CASE WHEN (h.dateacctfrom IS NOT NULL) THEN h.dateacctfrom ELSE fa.dateacct END)) AND (fa.dateacct <= CASE WHEN (h.dateacctto IS NOT NULL) THEN h.dateacctto ELSE fa.dateacct END));


ALTER TABLE adempiere.ChuBoe_trialbalance_detail_v OWNER TO adempiere;

------------------------------
-- view to summarize the above detail records.
------------------------------

CREATE VIEW ChuBoe_trialbalance_sum_v AS
    SELECT fa.ad_client_id, fa.ad_org_id, fa.c_acctschema_id, fa.account_id, fa.postingtype, fa.hdr_created AS created, fa.hdr_createdby AS createdby, fa.hdr_updated AS updated, fa.hdr_updatedby AS updatedby, sum(fa.amtsourcedr) AS amtsourcedr, sum(fa.amtsourcecr) AS amtsourcecr, sum((fa.amtsourcedr - fa.amtsourcecr)) AS amtsource, sum(fa.amtacctdr) AS amtacctdr, sum(fa.amtacctcr) AS amtacctcr, sum((fa.amtacctdr - fa.amtacctcr)) AS amtacct, fa.ChuBoe_trialbalance_hdr_id FROM ChuBoe_trialbalance_detail_v fa GROUP BY fa.ad_client_id, fa.ad_org_id, fa.c_acctschema_id, fa.account_id, fa.postingtype, fa.ChuBoe_trialbalance_hdr_id, fa.hdr_created, fa.hdr_createdby, fa.hdr_updated, fa.hdr_updatedby;


ALTER TABLE adempiere.ChuBoe_trialbalance_sum_v OWNER TO adempiere;