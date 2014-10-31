CREATE VIEW chuboe_rv_daily_bank_drafted AS
 SELECT xbsl.c_payment_id
   FROM c_bankstatementline xbsl
   JOIN c_bankstatement xbs ON xbsl.c_bankstatement_id = xbs.c_bankstatement_id
  WHERE xbs.docstatus = ANY (ARRAY['DR'::bpchar, 'IP'::bpchar]);

CREATE VIEW chuboe_rv_daily_bank_base AS
    SELECT ba.ad_client_id, ba.ad_org_id, ba.created, ba.createdby, ba.updated, ba.updatedby, ba.accountno, 
		round(ba.currentbalance, 2) AS currentbank_bal, ba.c_currency_id, 
		COALESCE(( SELECT round(sum(currencyconvert(xp.payamt, xp.c_currency_id, ba.c_currency_id, xp.datetrx::timestamp with time zone, NULL::numeric, xp.ad_client_id, xp.ad_org_id)), 2) AS round
           FROM c_payment xp
          WHERE xp.isreconciled = 'N'::bpchar AND xp.docstatus = 'CO'::bpchar AND ba.c_bankaccount_id = xp.c_bankaccount_id AND xp.isreceipt = 'N'::bpchar AND NOT (EXISTS ( SELECT dr.c_payment_id
                   FROM chuboe_rv_daily_bank_drafted dr
                  WHERE xp.c_payment_id = dr.c_payment_id))), 0::numeric) AS ap_noclear_norecon_bal, 
		COALESCE(( SELECT round(sum(currencyconvert(xp.payamt, xp.c_currency_id, ba.c_currency_id, xp.datetrx::timestamp with time zone, NULL::numeric, xp.ad_client_id, xp.ad_org_id)), 2) AS round
           FROM c_payment xp
          WHERE xp.isreconciled = 'N'::bpchar AND xp.docstatus = 'CO'::bpchar AND ba.c_bankaccount_id = xp.c_bankaccount_id AND xp.isreceipt = 'N'::bpchar AND (EXISTS ( SELECT dr.c_payment_id
                   FROM chuboe_rv_daily_bank_drafted dr
                  WHERE xp.c_payment_id = dr.c_payment_id))), 0::numeric) AS ap_yesclear_norecon_bal, 
		COALESCE(( SELECT round(sum(currencyconvert(xp.payamt, xp.c_currency_id, ba.c_currency_id, xp.datetrx::timestamp with time zone, NULL::numeric, xp.ad_client_id, xp.ad_org_id)), 2) AS round
           FROM c_payment xp
          WHERE xp.isreconciled = 'N'::bpchar AND xp.docstatus = 'CO'::bpchar AND ba.c_bankaccount_id = xp.c_bankaccount_id AND xp.isreceipt = 'Y'::bpchar AND NOT (EXISTS ( SELECT dr.c_payment_id
                   FROM chuboe_rv_daily_bank_drafted dr
                  WHERE xp.c_payment_id = dr.c_payment_id))), 0::numeric) AS ar_noclear_norecon_bal, 
		COALESCE(( SELECT round(sum(currencyconvert(xp.payamt, xp.c_currency_id, ba.c_currency_id, xp.datetrx::timestamp with time zone, NULL::numeric, xp.ad_client_id, xp.ad_org_id)), 2) AS round
           FROM c_payment xp
          WHERE xp.isreconciled = 'N'::bpchar AND xp.docstatus = 'CO'::bpchar AND ba.c_bankaccount_id = xp.c_bankaccount_id AND xp.isreceipt = 'Y'::bpchar AND (EXISTS ( SELECT dr.c_payment_id
                   FROM chuboe_rv_daily_bank_drafted dr
                  WHERE xp.c_payment_id = dr.c_payment_id))), 0::numeric) AS ar_yesclear_norecon_bal, 
		ba.c_bankaccount_id
   FROM c_bankaccount ba
  WHERE ba.isactive = 'Y'::bpchar;

CREATE VIEW chuboe_rv_daily_bank AS
SELECT chuboe_rv_daily_bank_base.ad_client_id, chuboe_rv_daily_bank_base.ad_org_id, 
         chuboe_rv_daily_bank_base.created, chuboe_rv_daily_bank_base.createdby, chuboe_rv_daily_bank_base.updated, 
         chuboe_rv_daily_bank_base.updatedby, chuboe_rv_daily_bank_base.c_currency_id, 
         chuboe_rv_daily_bank_base.currentbank_bal 
                  - chuboe_rv_daily_bank_base.ap_noclear_norecon_bal 
                  + chuboe_rv_daily_bank_base.ar_noclear_norecon_bal 
                  - chuboe_rv_daily_bank_base.ap_yesclear_norecon_bal 
                  + chuboe_rv_daily_bank_base.ar_yesclear_norecon_bal AS total_bal, 
         chuboe_rv_daily_bank_base.ap_noclear_norecon_bal, chuboe_rv_daily_bank_base.ar_noclear_norecon_bal, chuboe_rv_daily_bank_base.ap_yesclear_norecon_bal, 
         chuboe_rv_daily_bank_base.ar_yesclear_norecon_bal, chuboe_rv_daily_bank_base.c_bankaccount_id, chuboe_rv_daily_bank_base.c_bankaccount_id AS chuboe_rv_daily_bank_id, 
         chuboe_rv_daily_bank_base.currentbank_bal
   FROM chuboe_rv_daily_bank_base;