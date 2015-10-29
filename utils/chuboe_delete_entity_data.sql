-- Dangerous!!!!!
-- This file is not complete!!! It will take much work to get this script to execute the way you like.
-- I am including this file to help you get started if needed.

--here is a better solution for removing a specific client:
--https://bitbucket.org/CarlosRuiz_globalqss/idempiere-stuff/src/stuff/DeleteAdempiereClient_pg.SQL

delete from c_bp_relation;
delete from c_poskey;
delete from u_posterminal;
delete from c_uom_conversion;
delete from M_ProductDownload;
delete from M_Product where m_product_id not in (122);
delete from M_PriceList_Version;
delete from W_Store;
delete from dd_networkdistributionline;
delete from dd_networkdistribution;
delete from m_warehouse where m_warehouse_id not in (50003);
delete from M_Locator;
delete from M_Product_PO;
delete from M_Replenish;
delete from M_Product_Acct;
delete from PP_Product_BOM;
delete from S_Resource;
delete from M_ProductPrice;
delete from PP_Product_BOMLine;
delete from M_ProductPriceVendorBreak;
delete from M_Product_Trl;
delete from C_PaymentTerm_Trl;
delete from AD_WF_Node;
delete from M_Cost;
delete from M_Warehouse_Acct;
delete from AD_Workflow_Access;
delete from C_BP_Customer_Acct;
delete from C_BP_Employee_Acct;
delete from C_BP_Vendor_Acct;
delete from PP_Product_Planning;
delete from PP_Product_BOMLine_Trl;
delete from AD_Workflow_Trl;
delete from M_Shipper;
delete from C_PaymentTerm;
delete from AD_User where ad_user_id not in (100,0);
delete from C_BPartner_Product;
delete from AD_Workflow;
delete from M_PriceList;
delete from M_Requisition;
delete from R_Request;
delete from R_RequestAction;
delete from R_RequestUpdates;
delete from C_BPartner;
delete from C_BPartner_Location;
delete from C_Location;
delete from AD_WF_Node_Trl;
delete from AD_Image;
delete from AD_Attachment;
delete from ad_archive;
delete from pp_product_bom_trl;
delete from t_inventoryvalue;
delete from m_attributesetinstance;
delete from m_attributeinstance;
delete from m_attributeuse;
delete from m_attributeset;
delete from m_attributevalue;
delete from m_attribute;
delete from m_attributesearch;