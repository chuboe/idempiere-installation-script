--set GL Journal Description to context date by default.
update ad_column 
set defaultvalue = '@SQL=SELECT ''@#Date@ - ReasonForGLJournal'' FROM DUAL' 
WHERE AD_Column_ID=1630
;

--remove existing isDefaultFocus values from the below windows/tabs
update ad_field
set isDefaultFocus = 'N'
where ad_tab_id in (187, 293, 200008) --SOLine, POLine, GL Journal Line)
;

--set isDefaultFocus values for the below windows/tabs
update ad_field
set isDefaultFocus = 'Y'
where (lower(name) = 'product'
and ad_tab_id in (187, 293)) --SOLine, POLine
or (lower(name) = 'account'
and ad_tab_id in (200008)) --GL Journal Line
;

--Set the default value for the Material Receipt window => Generate Invoice From MR process => Pricelist parameter.
--otherwise, the process chooses the wrong pricelist.
update AD_Process_Para
set defaultvalue = -1
where AD_Process_Para_ID=183
;

--set the default to no. If yes, the system goes into a bad state where random addresses are choses for things like check runs.
update ad_column
set defaultvalue = 'N'
where ad_table_id = 293 --c_bpartner_location
and lower(columnname) in ('isbillto', 'ispayfrom', 'isremitto')
;

--lookups of type Search help windows load significantly faster. Table and Table Direct lookups add overhead.
update ad_column
set ad_reference_id = 30
where AD_Reference_ID in (19, 18) --table direct, table
and lower(columnname) in ('ad_user_id', 'c_bpartner_id', 'c_bpartner_location_id', 'createdby', 'updatedby', 'c_order_id', 'c_orderline_id', 'c_invoice_id', 'c_invoiceline_id', 'm_inout_id', 'm_inoutline_id', 'bill_bpartner_id', 'bill_location_id', 'bill_user_id', 'salesrep_id')
;

--update the accounting schema
update C_AcctSchema
set costingmethod = 'S', --standard costing
costinglevel = 'O', --org level costing
autoperiodcontrol = 'N', 
isallownegativeposting = 'N'
;