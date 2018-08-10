-- The purpose of this script is to help you create views that are easily used inside a BI or analytics tool.

-- Step 1: create dedicated BI access credentials
CREATE ROLE biaccess;
GRANT USAGE ON SCHEMA adempiere TO biaccess;
ALTER USER biaccess WITH PASSWORD 'SOMEPASSWORD897';
ALTER USER biaccess WITH LOGIN;

-- Step 2: execute the view in chuboe_bi_init_views.sql file

-- Step 3: give the BIAccess role read access to BI views
-- The following SQL will generate the SQL needed to give read access to your BI views.
SELECT   CONCAT('GRANT SELECT ON adempiere.', TABLE_NAME, ' to biaccess;')
FROM     INFORMATION_SCHEMA.TABLES
WHERE    TABLE_SCHEMA = 'adempiere'
    AND TABLE_NAME LIKE 'bi_%'
;
