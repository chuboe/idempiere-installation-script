-- !!!dangerous!!! This scripts deletes ADempiere and iDempiere transactional data. 
-- This script is useful when you need to prepare for go-live and you need to delete all your test data.
-- Be aware this updates all clients including GardenWorld
-- If you are running this script against a database with lots of transactions,
--   it may take a while. Below is a link to creating drop and restore constraints commands that greatly improve speed of this script.
--   http://www.chuckboecking.com/blog/bid/196810/Data-Migration-in-PostgreSQL-and-ADemipere-Open-Source-ERP
-- This script is designed for iDempiere. Be aware that ADempiere and iDempiere differ slightly. You may need to make small changes to accomodate ADempiere. 

-- To run this script from the command line, use this command:
-- sudo -u postgres psql -f chuboe_delete_transactional_data.sql -d idempiere

-- thanks to Rumman to improving the script!!

-- FYI - Carlos created a SQL script to completely remove a client:
-- https://bitbucket.org/CarlosRuiz_globalqss/idempiere-stuff/src/stuff/DeleteAdempiereClient_pg.SQL

set search_path to adempiere;

-- The below will help you limit what orgs you clean
-- ENHANCEMENT COMMENT BEGIN

	-- uncomment this statement
	-- CREATE TABLE IF NOT EXISTS chuboe_org_preserve (
	--     ad_org_id numeric
	-- );

	-- uncomment this statement - this and the next statement ensure a -1 entry exists before each script execution. You do not want this table to return null.
	-- delete from chuboe_org_preserve
	-- where ad_org_id = -1;

	-- uncomment this statement - see comments for previous statement.
	-- insert into chuboe_org_preserve
	-- values (-1);
	
	-- Add any ord_id to chuboe_org_preserve you wish to preserve. You do not need to do this every time the script executes.

	-- update all statements in the this file to include a where statement like this:
	-- delete from ad_changelog where ad_client_id not in (select ad_org_id from chuboe_org_preserve);

-- ENHANCEMENT COMMENT END

--delete from ChuBoe_Replenish;
--delete from ChuBoe_Replenish_Product_PO;
--delete from chuboe_replenish_multiplier;

delete from t_combinedaging;
delete from ad_changelog;
delete from c_allocationline;
delete from c_allocationhdr;
Update C_BankAccount Set CurrentBalance = 0;
delete from m_costhistory;
delete from m_costdetail;
delete from m_matchinv;
delete from m_matchpo;
delete from c_payselectionline;
delete from c_payselectioncheck;
delete from c_payselection;
Update C_Invoice set C_Cashline_ID = null;
Update C_Order set C_Cashline_ID = null;
delete from C_Cashline;
delete from C_Cash;
Update c_payment set C_Invoice_ID= null;
delete from C_CommissionAmt;
delete from C_CommissionDetail;
delete from C_CommissionLine;
delete from C_CommissionRun;
delete from C_Commission;
Delete from c_recurring_run;
Delete from c_recurring;
Delete from s_timeexpenseline;
Delete from s_timeexpense;
Delete from c_landedcostallocation;
Delete from c_landedcost;
delete from c_invoiceline;
delete from c_invoicetax;
delete from c_paymentallocate;
delete from c_bankstatementline;
delete from c_bankstatement;
Update c_invoice set c_Payment_ID = null;
Update c_order set c_Payment_ID= null;
delete from c_depositbatchline;
delete from c_depositbatch;
delete from c_orderpayschedule;
delete from c_paymenttransaction;
delete from c_payment ;
delete from c_paymentbatch ;
Update M_INOUTLINE Set C_Orderline_ID = null, M_RMALine_ID=null ;
Update M_INOUT Set C_Order_ID = null, C_Invoice_ID=null, M_RMA_ID=null;
Update C_INVOICE Set M_RMA_ID = null;
update R_Request set m_rma_id = null;
delete from m_rmatax;
delete from M_RMAline;
delete from M_RMA;
delete from c_Invoice ;
delete from PP_MRP ;
delete from m_requisitionline  ;
delete from m_requisition ;
update pp_order set c_orderline_id = null;
delete from c_orderline ;
delete from c_ordertax ;
update r_request set c_order_id = null, M_inout_id = null ;
update r_requestaction set c_order_id = null, M_inout_id = null ;
delete from c_orderlandedcostallocation;
delete from c_orderlandedcost;
delete from c_order ;
delete from fact_acct ;
delete from fact_acct_summary ;
delete from gl_journalbatch ;
delete from gl_journal ; 
delete from gl_journalline ; 
--delete from m_storage ;  -- use this for ADempiere
delete from m_storageonhand;
delete from m_storagereservation;
delete from m_transaction ;
delete from m_packageline ;
delete from m_package ;
update c_projectissue set m_inoutline_id = null;
delete from m_inoutline ; 
delete from m_inout ;
delete from m_inoutconfirm ; 
delete from m_inoutlineconfirm ; 
delete from m_inoutlinema ; 
delete from m_inventoryline ; 
delete from m_inventory ;
delete from m_inventorylinema  ; 
delete from m_Movementline ; 
delete from m_Movement ; 
delete from m_Movementconfirm ; 
delete from m_Movementlineconfirm ; 
delete from m_Movementlinema ; 
delete from m_production ;
delete from m_productionplan ; 
delete from m_productionline ; 
delete from c_dunningrun ; 
delete from c_dunningrunline ; 
delete from c_dunningrunentry ; 
delete from AD_WF_EventAudit  ;
delete from AD_WF_Process  ;
Update M_Cost SET CurrentQty=0, CumulatedAMT=0, CumulatedQty=0  ;
Update C_BPartner SET ActualLifetimeValue=0, SO_CreditUsed=0, TotalOpenBalance=0  ;
delete from R_RequestUpdates ;
delete from R_RequestUpdate ;
delete from R_RequestAction ;
delete from R_Request ;
Delete from pp_cost_collectorma  ;
Delete from pp_order_nodenext  ;
Delete from pp_order_node_trl  ;
Delete from pp_order_workflow_trl  ;
Delete from pp_order_bomline_trl  ;
Delete from pp_order_bom_trl  ;
update pp_cost_collector set pp_order_bomline_id = null;
Delete from pp_order_bomline  ;
Delete from pp_order_bom  ;
Delete from PP_Cost_Collector  ;
Update pp_order_workflow set PP_Order_Node_id = null; 
Delete from PP_Order_Node ;
Delete from PP_Order_Workflow  ;
Delete from pp_order_cost  ;
Delete from PP_Order   ;
delete from dd_orderline;
delete from dd_order;
delete from t_replenish;
delete from i_order;
delete from i_invoice;
delete from i_payment;
delete from I_Inventory;
delete from I_GLJournal;
delete from m_distributionrunline;
delete from c_rfqline;
delete from s_timeexpense;
delete from s_timeexpenseline;
delete from ad_note;
delete from c_projectline where c_project_id not in (select c_project_id from c_acctschema_element where c_project_id is not null);
delete from c_projecttask where c_projectphase_id not in (select pp.c_projectphase_id from c_acctschema_element ae join c_projectphase pp on ae.c_project_id = pp.c_project_id);
delete from c_projectphase where c_project_id not in (select c_project_id from c_acctschema_element where c_project_id is not null);
delete from c_project where c_project_id not in (select c_project_id from c_acctschema_element where c_project_id is not null);
delete from s_resourceassignment;
--update AD_Sequence set currentnext=startno where isTableID='N';

--delete from ChuBoe_Replenish_Action;
--delete from ChuBoe_Replenish_TempAction;
--delete from ChuBoe_Replenish_Date;
--delete from ChuBoe_Replenish_Pressure;
--delete from ChuBoe_Replenish_Storage;
--delete from ChuBoe_Replenish_Run;
