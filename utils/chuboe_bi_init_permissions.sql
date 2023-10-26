-- The purpose of this script is to help you create views that are easily used inside a BI or analytics tool.

-- Step 1: create dedicated BI access credentials
CREATE ROLE biaccess;
GRANT USAGE ON SCHEMA adempiere TO biaccess;
ALTER USER biaccess WITH PASSWORD 'SOMEPASSWORD897';
ALTER USER biaccess WITH LOGIN;
ALTER ROLE biaccess SET search_path TO adempiere;

-- Step 2: execute the view in chuboe_bi_init_views.sql file

-- Step 3: give the BIAccess role read access to BI views
-- The following SQL will generate the SQL needed to give read access to your BI views.
SELECT   CONCAT('GRANT SELECT ON adempiere.', TABLE_NAME, ' to biaccess;')
FROM     INFORMATION_SCHEMA.TABLES
WHERE    TABLE_SCHEMA = 'adempiere'
    AND TABLE_NAME LIKE 'bi_%'
;

---- Example of manually creating new user/role with specific permissions ----
--CREATE ROLE someuser WITH PASSWORD 'somepassword';
--GRANT USAGE ON SCHEMA adempiere TO someuser;
--GRANT SELECT ON adempiere.some_table_or_view to someuser;
--ALTER ROLE someuser SET search_path = adempiere;
--ALTER USER someuser WITH LOGIN;
