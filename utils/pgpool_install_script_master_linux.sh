# This is not a script yet!!! It is a collection of commands to run - a work in progress.

# This script is used to create a dedicated pgpool2 server to perform two tasks:
# 1) automate the fail over to a second database in case the first server is not available
# 2) provide load balancing of read-only queries
# You would only use this feature if you were supporting hundreds of concurrent users. 
#    Otherwise, just use the standard replication to provide a hot-standby server. 
#    This is accomplished by using the -r flag during normal installation.


#Pool Machine

# Get rid of the annoying sudo IP error
wget bitbucket.org/cboecking/idempiere-installation-script/raw/default/utils/setHostName.sh;
chmod +x setHostName.sh;
sudo ./setHostName.sh;

# Install components and crate backups
sudo apt-get -y install pgpool2
# sudo apt-get -y install postgresql-9.3-pgpool2 # not needed in simple cases
sudo apt-get -y install postgresql-client-9.3
sudo service pgpool2 stop
sudo cp -p /etc/pgpool2/pgpool.conf{,.back};
sudo cp -p /etc/pgpool2/pcp.conf{,.back};

# Pull reference config from documentation
sudo cp /usr/share/doc/pgpool2/examples/pgpool.conf.sample-stream.gz /etc/pgpool2/
sudo gunzip pgpool.conf.sample-stream.gz
sudo mv pgpool.conf.sample-stream pgpool.conf

# update the config file to point to your database servers (Master and Backup)
# be sure to swap out the correct IPs below.
sudo sed -i "s|listen_addresses = 'localhost'|listen_addresses = '*'|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|backend_hostname0 = 'host1'|backend_hostname0 = '172.30.0.165'|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|backend_data_directory0 = '/data'|backend_data_directory0 = '/var/lib/postgresql/9.3/main/'|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|backend_flag0 = 'ALLOW_TO_FAILOVER'|backend_flag0 = 'DISALLOW_TO_FAILOVER'|" /etc/pgpool2/pgpool.conf;

sudo sed -i "s|#backend_hostname1 = 'host2'|backend_hostname1 = '172.30.0.177'|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|#backend_port1 = 5433|backend_port1 = 5432|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|#backend_weight1 = 1|backend_weight1 = 1|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|#backend_data_directory1 = '/data1'|backend_data_directory1 = '/var/lib/postgresql/9.3/main/'|" /etc/pgpool2/pgpool.conf;
sudo sed -i "s|#backend_flag1 = 'ALLOW_TO_FAILOVER'|backend_flag1 = 'DISALLOW_TO_FAILOVER'|" /etc/pgpool2/pgpool.conf;

# make all backend servers pg_hba.conf = trust and restart DBs
# making them trust is just temporary!!!!!!!!!!!!!! Make sure you are behind a firewall!!!!!

sudo service pgpool2 start

sudo -u postgres psql -p 5433 postgres

#Test queries
sudo su postgres 
psql -c "CREATE DATABASE testdb1;"
psql -d testdb1 -c "CREATE TABLE testtable1 (i int);"
psql -d testdb1 -c "INSERT INTO testtable1 values (0);"
psql -d testdb1 -c "SELECT * from testtable1;"

#use psql from your back machine to see if the new database and tables exist

#Stop here
#next action - use MD5 authentication

Master DB
#sudo echo "host	all	$PGPOOL_USER	0.0.0.0/0	md5" >> /etc/postgresql/9.3/main/pg_hba.conf
#sudo -u postgres psql -c "CREATE ROLE $PGPOOL_USER LOGIN PASSWORD '"$DBPASS"';"
  - note that the above statement will automatically propogate to the backup

Backup DB
#sudo echo "host	all	$PGPOOL_USER	0.0.0.0/0	md5" >> /etc/postgresql/9.3/main/pg_hba.conf

# Below is needed for active failover
sudo chmod 0666 pcp.conf
echo $PGPOOL_USER:`pg_md5 $DBPASS` >> pcp.conf
sudo chmod 0640 pcp.conf

# Need pool_passwd file
# See "Authentication / Access Controls" section of http://www.pgpool.net/docs/latest/pgpool-en.html for reference.

#Reference
sudo sed -i "s|OLD|NEW|" /PATH/FILENAME