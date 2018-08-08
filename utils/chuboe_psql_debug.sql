-- the purpose of this file is to create views from the most useful queries in PostgreSQL to resolve issues.

-- shows SQL statement from blocking and blocked statements
Create or replace view chuboe_lock_detail_v as
SELECT blocked_locks.pid     AS blocked_pid,
         blocked_activity.usename  AS blocked_user,
         blocking_locks.pid     AS blocking_pid,
         blocking_activity.usename AS blocking_user,
         blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS current_statement_in_blocking_process
   FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks 
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 
    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.GRANTED;

-- shows blocking PIDs in order
create or replace view chuboe_lock_recursive_v as 
WITH RECURSIVE
     c(requested, CURRENT) AS
       ( VALUES
         ('AccessShareLock'::text, 'AccessExclusiveLock'::text),
         ('RowShareLock'::text, 'ExclusiveLock'::text),
         ('RowShareLock'::text, 'AccessExclusiveLock'::text),
         ('RowExclusiveLock'::text, 'ShareLock'::text),
         ('RowExclusiveLock'::text, 'ShareRowExclusiveLock'::text),
         ('RowExclusiveLock'::text, 'ExclusiveLock'::text),
         ('RowExclusiveLock'::text, 'AccessExclusiveLock'::text),
         ('ShareUpdateExclusiveLock'::text, 'ShareUpdateExclusiveLock'::text),
         ('ShareUpdateExclusiveLock'::text, 'ShareLock'::text),
         ('ShareUpdateExclusiveLock'::text, 'ShareRowExclusiveLock'::text),
         ('ShareUpdateExclusiveLock'::text, 'ExclusiveLock'::text),
         ('ShareUpdateExclusiveLock'::text, 'AccessExclusiveLock'::text),
         ('ShareLock'::text, 'RowExclusiveLock'::text),
         ('ShareLock'::text, 'ShareUpdateExclusiveLock'::text),
         ('ShareLock'::text, 'ShareRowExclusiveLock'::text),
         ('ShareLock'::text, 'ExclusiveLock'::text),
         ('ShareLock'::text, 'AccessExclusiveLock'::text),
         ('ShareRowExclusiveLock'::text, 'RowExclusiveLock'::text),
         ('ShareRowExclusiveLock'::text, 'ShareUpdateExclusiveLock'::text),
         ('ShareRowExclusiveLock'::text, 'ShareLock'::text),
         ('ShareRowExclusiveLock'::text, 'ShareRowExclusiveLock'::text),
         ('ShareRowExclusiveLock'::text, 'ExclusiveLock'::text),
         ('ShareRowExclusiveLock'::text, 'AccessExclusiveLock'::text),
         ('ExclusiveLock'::text, 'RowShareLock'::text),
         ('ExclusiveLock'::text, 'RowExclusiveLock'::text),
         ('ExclusiveLock'::text, 'ShareUpdateExclusiveLock'::text),
         ('ExclusiveLock'::text, 'ShareLock'::text),
         ('ExclusiveLock'::text, 'ShareRowExclusiveLock'::text),
         ('ExclusiveLock'::text, 'ExclusiveLock'::text),
         ('ExclusiveLock'::text, 'AccessExclusiveLock'::text),
         ('AccessExclusiveLock'::text, 'AccessShareLock'::text),
         ('AccessExclusiveLock'::text, 'RowShareLock'::text),
         ('AccessExclusiveLock'::text, 'RowExclusiveLock'::text),
         ('AccessExclusiveLock'::text, 'ShareUpdateExclusiveLock'::text),
         ('AccessExclusiveLock'::text, 'ShareLock'::text),
         ('AccessExclusiveLock'::text, 'ShareRowExclusiveLock'::text),
         ('AccessExclusiveLock'::text, 'ExclusiveLock'::text),
         ('AccessExclusiveLock'::text, 'AccessExclusiveLock'::text)
       ),
     l AS
       (
         SELECT
             (locktype,DATABASE,relation::regclass::text,page,tuple,virtualxid,transactionid,classid,objid,objsubid) AS target,
             virtualtransaction,
             pid,
             mode,
             GRANTED
           FROM pg_catalog.pg_locks
       ),
     t AS
       (
         SELECT
             blocker.target::text  AS blocker_target,
             blocker.pid     AS blocker_pid,
             blocker.mode    AS blocker_mode,
             blocked.target::text  AS target,
             blocked.pid     AS pid,
             blocked.mode    AS mode
           FROM l blocker
           JOIN l blocked
             ON ( NOT blocked.GRANTED
              AND blocker.GRANTED
              AND blocked.pid != blocker.pid
              AND blocked.target IS NOT DISTINCT FROM blocker.target)
           JOIN c ON (c.requested = blocked.mode AND c.CURRENT = blocker.mode)
       ),
     r AS
       (
         SELECT
             blocker_target,
             blocker_pid,
             blocker_mode,
             '1'::INT        AS depth,
             target,
             pid,
             mode,
             blocker_pid::text || ',' || pid::text AS seq
           FROM t
         UNION ALL
         SELECT
             blocker.blocker_target,
             blocker.blocker_pid,
             blocker.blocker_mode,
             blocker.depth + 1,
             blocked.target,
             blocked.pid,
             blocked.mode,
             blocker.seq || ',' || blocked.pid::text
           FROM r blocker
           JOIN t blocked
             ON (blocked.blocker_pid = blocker.pid)
           WHERE blocker.depth < 1000
       )
SELECT * FROM r
  ORDER BY seq;
