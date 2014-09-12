create or replace view chuboe_quicksearch as
Select value, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from M_Product
union all
Select Name, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from M_Product
union all
Select UPC, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from M_Product
union all
Select sku, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from M_Product
union all
Select name, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_bpartner
union all
Select name2, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_bpartner
union all
Select ReferenceNo, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_bpartner
union all
Select name, ad_user_id as record_id, 114::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from ad_user
union all
Select email, ad_user_id as record_id, 114::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from ad_user
union all
Select name, c_bpartner_location_id as record_id, 293::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_bpartner_location
union all
Select documentno, c_order_id as record_id, 259::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_order
union all
Select documentno, c_invoice_id as record_id, 318::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_invoice
union all
Select documentno, c_payment_id as record_id, 335::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from c_payment
union all
Select documentno, m_inout_id as record_id, 319::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from m_inout
union all
Select documentno, m_inventory_id as record_id, 321::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from m_inventory
union all
Select documentno, m_movement_id as record_id, 323::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from m_movement
union all
Select documentno, m_production_id as record_id, 325::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby
from m_production
;