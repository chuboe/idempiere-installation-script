--Create View
create or replace view chuboe_quicksearch as
Select value, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Product'::text as Description
from M_Product
union all
Select Name, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Product'::text as Description
from M_Product
union all
Select UPC, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Product'::text as Description
from M_Product
union all
Select sku, m_product_id as record_id, 208::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Product'::text as Description
from M_Product
union all
Select value, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Business Partner'::text as Description
from c_bpartner
union all
Select name, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Business Partner'::text as Description
from c_bpartner
union all
Select name2, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Business Partner'::text as Description
from c_bpartner
union all
Select ReferenceNo, c_bpartner_id as record_id, 291::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Business Partner'::text as Description
from c_bpartner
union all
Select name, ad_user_id as record_id, 114::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Contact or User'::text as Description
from ad_user
union all
Select email, ad_user_id as record_id, 114::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Contact or User'::text as Description
from ad_user
union all
Select name, c_bpartner_location_id as record_id, 293::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'BP Location'::text as Description
from c_bpartner_location
union all
Select documentno, c_order_id as record_id, 259::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Order'::text as Description
from c_order
union all
Select documentno, c_invoice_id as record_id, 318::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Invoice'::text as Description
from c_invoice
union all
Select documentno, c_payment_id as record_id, 335::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Payment'::text as Description
from c_payment
union all
Select documentno, m_inout_id as record_id, 319::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Ship/Receipt'::text as Description
from m_inout
union all
Select documentno, m_inventory_id as record_id, 321::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Physical Inventory'::text as Description
from m_inventory
union all
Select documentno, m_movement_id as record_id, 323::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Inventory Move'::text as Description
from m_movement
union all
Select documentno, m_production_id as record_id, 325::numeric as ad_table_id,
ad_client_id, 0::numeric as ad_org_id, created, createdby, updated, updatedby,
'Production'::text as Description
from m_production
;

--Create Indexes
CREATE INDEX chuboe_m_product_sku_idx ON m_product USING btree (sku);
CREATE INDEX chuboe_c_bpartner_name2_ref_idx ON c_bpartner USING btree (name2, ReferenceNo);
CREATE INDEX chuboe_ad_user_name_idx ON ad_user USING btree (name);
CREATE INDEX chuboe_c_bpartner_location_name_idx ON c_bpartner_location USING btree (name);
CREATE INDEX chuboe_c_payment_docno_idx ON c_payment USING btree (documentno);
CREATE INDEX chuboe_m_inventory_docno_idx ON m_inventory USING btree (documentno);
CREATE INDEX chuboe_m_movement_docno_idx ON m_movement USING btree (documentno);
CREATE INDEX chuboe_m_production_docno_idx ON m_production USING btree (documentno);