# This is not a script yet!!! It is a collection of commands to run - a work in progress.

# pgbadger anazlyses postgresql logs - http://dalibo.github.io/pgbadger/
# Note: the ubuntu version through apt-get is old (v3)

# for pgbadger to work, you need to set the appropriate log settings in postgresql.conf
# The installation script uses https://www.pgconfig.org/#/tuning to tune your database when you install iDempiere and the database on separate machines.
# Look at the bottom of your /etc/postgresql/$PGVERSION/main/postgresql.conf file to see if the setting have been updated. 
# If not, use https://www.pgconfig.org/#/tuning to create pgbadger settings and append to your postgresql.conf file.
# The following commands will do this for you. Note that you must fill in the parameters manually.
    # curl 'https://api.pgconfig.org/v1/tuning/get-config?environment_name=OLTP&format=conf&include_pgbadger=true&log_format=csvlog&max_connections=100&pg_version='$PGVERSION'&total_ram='$AVAIL_MEMORY'MB' >> $TEMP_DIR/pg.conf
    # cat $TEMP_DIR/pg.conf | sudo tee -a /etc/postgresql/$PGVERSION/main/postgresql.conf

CURRENT_VER="9.1"

sudo apt-get update

sudo apt-get install make
mkdir pgbadger_install
cd pgbadger_install

#note: you can get the most recent URL from http://sf.net/project/pgbadger
wget http://downloads.sourceforge.net/project/pgbadger/$CURRENT_VER/pgbadger-$CURRENT_VER.tar.gz -O pgbadger-$CURRENT_VER.tar.gz

tar xzf pgbadger-$CURRENT_VER.tar.gz
cd pgbadger-$CURRENT_VER/
perl Makefile.PL INSTALLDIRS=vendor
make && sudo make install

sudo mkdir /var/reports
sudo mkdir /var/reports/pgbadger/
sudo chown ubuntu:ubuntu /var/reports/pgbadger/

# verify installation
pgbadger --version

### Usage Recommendations ###
# single command - simple test and info
# pgbadger /var/log/postgresql/postgresql-9.3*

#add the following to cron to create an ongoing report
# 0 4 * * * /usr/bin/pgbadger -I -q /var/log/postgresql/postgresql.log.1 -O /var/reports/pgbadger/

