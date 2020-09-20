-- The purpose of this query is to help you find usage of specif fields (column names)in the system. Example: Let say you want to know what impact the BP Location => isPayFrom field has on the system. This view will show you everywhere the the isPayFrom field is referenced. 

-- Action: this view needs to be extended to include field overrides and client customizations

Create view X_AppDictionarySearch_V as
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 101::numeric as AD_Table_ID, ad_column_id as record_id, lower(columnsql) as code, 'Column SQL'::text as messagetext from ad_column
union
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 101 as AD_Table_ID, ad_column_id as record_id, lower(defaultvalue) as code, 'Column Default Logic' as messagetext from ad_column
union
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 101 as AD_Table_ID, ad_column_id as record_id, lower(readonlylogic) as code, 'Column Read Only Logic' as messagetext from ad_column
union 
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 101 as AD_Table_ID, ad_column_id as record_id, lower(Mandatorylogic) as code, 'Column Mandatory Logic' as messagetext from ad_column
union 
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 107 as AD_Table_ID, ad_field_id as record_id, lower(defaultvalue) as code, 'Field Default Logic' as messagetext from ad_field
union 
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 107 as AD_Table_ID, ad_field_id as record_id, lower(displaylogic) as code, 'Field Display Logic' as messagetext from ad_field
union
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 102 as AD_Table_ID, AD_Reference_ID as record_id, lower(whereclause) as code, 'Reference Where Clause' as messagetext from AD_Ref_Table
union
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 108 as AD_Table_ID, AD_Val_Rule_ID as record_id, lower(code) as code, 'Validation Rule' as messagetext from AD_Val_Rule
union
select 0 as ad_client_id, 0 as ad_org_id, date_trunc('day',now()) as created, 100 as createdby, date_trunc('day',now()) as updated, 100 as updatedby, null as AD_Table_ID, null as record_id, lower((pg_views.viewname::text || ':: '::text) || pg_views.definition) as code, 'View contents' as messagetext from pg_views
union
select 0 as ad_client_id, 0 as ad_org_id, date_trunc('day',now()) as created, 100 as createdby, date_trunc('day',now()) as updated, 100 as updatedby, null as AD_Table_ID, null as record_id, lower((pg_proc.proname::text || ':: '::text) || pg_proc.prosrc) as code, 'Function contents' as messagetext from pg_proc
union
select ad_client_id, ad_org_id, created, createdby, updated, updatedby, 284 as AD_Table_ID, ad_process_id as record_id, lower(classname) as code, 'Report and Process Classname' as messagetext from ad_process
;
