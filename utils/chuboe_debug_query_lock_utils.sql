
CREATE VIEW adempiere.chuboe_query_long_running_v AS
select * from (select now() - query_start as duration,* from pg_stat_activity where pg_stat_activity.query <> ''::text ) as ad where duration > interval '5 minutes' order by duration;

CREATE VIEW adempiere.chuboe_query_large_table_v AS
SELECT nspname || '.' || relname AS "relation",
    pg_size_pretty(pg_relation_size(C.oid)) AS "size"
  FROM pg_class C
  LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
  WHERE nspname NOT IN ('pg_catalog', 'information_schema')
  ORDER BY pg_relation_size(C.oid) DESC
  LIMIT 50;

CREATE VIEW adempiere.chuboe_query_lock_detail_v AS
 SELECT blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
   FROM (((pg_locks blocked_locks
     JOIN pg_stat_activity blocked_activity ON ((blocked_activity.pid = blocked_locks.pid)))
     JOIN pg_locks blocking_locks ON ((((((((((((blocking_locks.locktype = blocked_locks.locktype) AND (NOT (blocking_locks.database IS DISTINCT FROM blocked_locks.database))) AND (NOT (blocking_locks.relation IS DISTINCT FROM blocked_locks.relation))) AND (NOT (blocking_locks.page IS DISTINCT FROM blocked_locks.page))) AND (NOT (blocking_locks.tuple IS DISTINCT FROM blocked_locks.tuple))) AND (NOT (blocking_locks.virtualxid IS DISTINCT FROM blocked_locks.virtualxid))) AND (NOT (blocking_locks.transactionid IS DISTINCT FROM blocked_locks.transactionid))) AND (NOT (blocking_locks.classid IS DISTINCT FROM blocked_locks.classid))) AND (NOT (blocking_locks.objid IS DISTINCT FROM blocked_locks.objid))) AND (NOT (blocking_locks.objsubid IS DISTINCT FROM blocked_locks.objsubid))) AND (blocking_locks.pid <> blocked_locks.pid))))
     JOIN pg_stat_activity blocking_activity ON ((blocking_activity.pid = blocking_locks.pid)))
  WHERE (NOT blocked_locks.granted);

CREATE VIEW adempiere.chuboe_query_lock_recursive_v AS
 WITH RECURSIVE c(requested, current) AS (
         VALUES ('AccessShareLock'::text,'AccessExclusiveLock'::text), ('RowShareLock'::text,'ExclusiveLock'::text), ('RowShareLock'::text,'AccessExclusiveLock'::text), ('RowExclusiveLock'::text,'ShareLock'::text), ('RowExclusiveLock'::text,'ShareRowExclusiveLock'::text), ('RowExclusiveLock'::text,'ExclusiveLock'::text), ('RowExclusiveLock'::text,'AccessExclusiveLock'::text), ('ShareUpdateExclusiveLock'::text,'ShareUpdateExclusiveLock'::text), ('ShareUpdateExclusiveLock'::text,'ShareLock'::text), ('ShareUpdateExclusiveLock'::text,'ShareRowExclusiveLock'::text), ('ShareUpdateExclusiveLock'::text,'ExclusiveLock'::text), ('ShareUpdateExclusiveLock'::text,'AccessExclusiveLock'::text), ('ShareLock'::text,'RowExclusiveLock'::text), ('ShareLock'::text,'ShareUpdateExclusiveLock'::text), ('ShareLock'::text,'ShareRowExclusiveLock'::text), ('ShareLock'::text,'ExclusiveLock'::text), ('ShareLock'::text,'AccessExclusiveLock'::text), ('ShareRowExclusiveLock'::text,'RowExclusiveLock'::text), ('ShareRowExclusiveLock'::text,'ShareUpdateExclusiveLock'::text), ('ShareRowExclusiveLock'::text,'ShareLock'::text), ('ShareRowExclusiveLock'::text,'ShareRowExclusiveLock'::text), ('ShareRowExclusiveLock'::text,'ExclusiveLock'::text), ('ShareRowExclusiveLock'::text,'AccessExclusiveLock'::text), ('ExclusiveLock'::text,'RowShareLock'::text), ('ExclusiveLock'::text,'RowExclusiveLock'::text), ('ExclusiveLock'::text,'ShareUpdateExclusiveLock'::text), ('ExclusiveLock'::text,'ShareLock'::text), ('ExclusiveLock'::text,'ShareRowExclusiveLock'::text), ('ExclusiveLock'::text,'ExclusiveLock'::text), ('ExclusiveLock'::text,'AccessExclusiveLock'::text), ('AccessExclusiveLock'::text,'AccessShareLock'::text), ('AccessExclusiveLock'::text,'RowShareLock'::text), ('AccessExclusiveLock'::text,'RowExclusiveLock'::text), ('AccessExclusiveLock'::text,'ShareUpdateExclusiveLock'::text), ('AccessExclusiveLock'::text,'ShareLock'::text), ('AccessExclusiveLock'::text,'ShareRowExclusiveLock'::text), ('AccessExclusiveLock'::text,'ExclusiveLock'::text), ('AccessExclusiveLock'::text,'AccessExclusiveLock'::text)
        ), l AS (
         SELECT ROW(pg_locks.locktype, pg_locks.database, ((pg_locks.relation)::regclass)::text, pg_locks.page, pg_locks.tuple, pg_locks.virtualxid, pg_locks.transactionid, pg_locks.classid, pg_locks.objid, pg_locks.objsubid) AS target,
            pg_locks.virtualtransaction,
            pg_locks.pid,
            pg_locks.mode,
            pg_locks.granted
           FROM pg_locks
        ), t AS (
         SELECT (blocker.target)::text AS blocker_target,
            blocker.pid AS blocker_pid,
            blocker.mode AS blocker_mode,
            (blocked.target)::text AS target,
            blocked.pid,
            blocked.mode
           FROM ((l blocker
             JOIN l blocked ON (((((NOT blocked.granted) AND blocker.granted) AND (blocked.pid <> blocker.pid)) AND (NOT (blocked.target IS DISTINCT FROM blocker.target)))))
             JOIN c ON (((c.requested = blocked.mode) AND (c.current = blocker.mode))))
        ), r AS (
         SELECT t.blocker_target,
            t.blocker_pid,
            t.blocker_mode,
            1 AS depth,
            t.target,
            t.pid,
            t.mode,
            (((t.blocker_pid)::text || ','::text) || (t.pid)::text) AS seq
           FROM t
        UNION ALL
         SELECT blocker.blocker_target,
            blocker.blocker_pid,
            blocker.blocker_mode,
            (blocker.depth + 1),
            blocked.target,
            blocked.pid,
            blocked.mode,
            ((blocker.seq || ','::text) || (blocked.pid)::text)
           FROM (r blocker
             JOIN t blocked ON ((blocked.blocker_pid = blocker.pid)))
          WHERE (blocker.depth < 1000)
        )
 SELECT r.blocker_target,
    r.blocker_pid,
    r.blocker_mode,
    r.depth,
    r.target,
    r.pid,
    r.mode,
    r.seq
   FROM r
  ORDER BY r.seq;
