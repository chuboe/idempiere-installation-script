# Note: this is a working document - it is not a script yet.

# references:
# http://searchadmin.org/Thread-ha-postgresql-cluster-by-streaming-replication-pgpool-ii/
# https://github.com/bmomjian/pgpool2/blob/master/pgpool.conf.sample-stream

# Set the following
# backend_flag0 = 'DISALLOW_TO_FAILOVER'
# backend_flag1 = 'DISALLOW_TO_FAILOVER'
# num_init_children = # depends on math
# max_pool = # depends on math
# replication_mode = off
# load_balance_mode = on
# master_slave_mode = on
# master_slave_sub_mode = 'stream'
# parallel_mode = off