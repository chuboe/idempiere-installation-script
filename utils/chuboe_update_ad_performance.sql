--drop tables to be created below
DROP TABLE IF EXISTS chuboe_perfmax_optimize;
DROP TABLE IF EXISTS chuboe_perfmax_coltotable;
DROP TABLE IF EXISTS chuboe_perfmax_bigtables;

--Wish list and thoughts
---- show all columnsql
---- show all identifiers that are foreign keys (compound foreign keys)
---- look at home => Activities (Document Status) performance
---- Add more here...
---- Review logs in pgbadger

--Update all views to use Search instead of Table or Table Direct. The reason is that no view should ever present a user with dropdown since all fields are read only. You can run this query as often as you wish since new views will default to Table references.
update ad_column
set ad_reference_id = 30
where ad_column_id in (
select c.ad_column_id
 from ad_column c
 join ad_table t on c.ad_table_id = t.ad_table_id
 where isview = 'Y'
  and c.AD_Reference_ID in (18,19)
);

--Update all CreatedBy and UpdatedBy references to Search.The reason is that no one should editing these fields.
update ad_column
set ad_reference_id = 30
where ad_column_id in (
select c.ad_column_id
 from ad_column c
 where c.columnname in ('CreatedBy','UpdatedBy')
  and c.AD_Reference_ID in (18,19)
);

--Create list of big tables
CREATE TABLE chuboe_perfmax_bigtables AS
SELECT
 relname AS objectname, reltuples AS entries, pg_size_pretty(relpages::bigint*8*1024) AS size, relpages::bigint as size_ugly
FROM pg_class
 WHERE reltuples >= 55
and relkind = 'r';
--select * from chuboe_perfmax_bigtables order by entries desc;


--Extract out the TableName from the Column Name
CREATE TABLE chuboe_perfmax_coltotable AS
Select
c.ad_column_id, c.columnname, coalesce(lower(rtt.tablename),lower(SUBSTR (TRIM (c.columnname), 1, LENGTH (TRIM (c.columnname)) - 3))) as tablename
from ad_column c
left outer join ad_reference r on c.ad_reference_value_id = r.ad_reference_id
left outer join AD_Ref_Table rt on rt.ad_reference_id = r.ad_reference_id
left outer join ad_table rtt on rt.ad_table_id = rtt.ad_table_id
where c.AD_Reference_ID in (18,19)
and lower(columnname) like '%_id';

--Update the necessary columns. Note that I included a line about ad_val_rule_id (Dynamic Validation). The reason is that Search dialogs with Dynamic Validation that exist in a subtab might not perform as expected
--The below is commented out because you must test before you execute!!
--update ad_column set ad_reference_id = 30
----select columnname, ad_reference_id from ad_column
--where ad_column_id in
--(
--select ad_column_id
--from chuboe_perfmax_coltotable
--where tablename in
--(
--select objectname from chuboe_perfmax_bigtables
--)
--)
--and ad_val_rule_id is null
--and lower(columnname) not in ('ad_org_id','user1_id','user2_id','ad_val_rule_id')
--;

--The following query will help you focus on creating the proper indexes. It shows you what dynamic validations exist for all remaining Table Direct and Table references.
create table chuboe_perfmax_optimize as
select count(*) as count, c.columnname, r.name as DynValName, r.code as validationcode,
coltab.tablename,
bt.entries as rowcount,
(select array_to_string(array(
select t.tablename
--|| coalesce('_'||(select entries from chuboe_perfmax_bigtables where lower(t.tablename) = objectname),'')
from ad_table t where t.ad_table_id in
(
select xc.ad_table_id
from ad_column xc
where xc.columnname = c.columnname
and xc.ad_val_rule_id = c.ad_val_rule_id
and xc.AD_Reference_ID in (18,19)
)
order by lower (t.tablename)
),', ')
) as RefFromTables
from ad_column c
join AD_Val_Rule r on c.ad_val_rule_id = r.ad_val_rule_id
left join chuboe_perfmax_coltotable coltab on c.ad_column_id = coltab.ad_column_id
left join chuboe_perfmax_bigtables bt on coltab.tablename = bt.objectname
where c.AD_Reference_ID in (18,19)
group by c.columnname, r.name, r.code, c.ad_val_rule_id, coltab.tablename, bt.entries
order by c.columnname;
--select count, columnname, tablename, rowcount, validationcode from chuboe_perfmax_optimize where rowcount > 1000
;
