# This is not a script yet!!! It is a collection of commands to run - a work in progress.

# pgbadger anazlyses postgresql logs - https://pgbadger.darold.net/
# Note: the ubuntu version through apt-get is old

# for pgbadger to work, you need to set the appropriate log settings in postgresql.conf
# The installation script uses https://www.pgconfig.org/#/tuning to tune your database when you install iDempiere and the database on separate machines.
# Look at the bottom of your /etc/postgresql/$PGVERSION/main/postgresql.conf file to see if the setting have been updated. 
# If not, use https://www.pgconfig.org/#/tuning to create pgbadger settings and append to your postgresql.conf file.
# The following commands will do this for you. Note that you must fill in the parameters manually.
    # curl 'https://api.pgconfig.org/v1/tuning/get-config?environment_name=OLTP&format=conf&include_pgbadger=true&log_format=csvlog&max_connections=100&pg_version='$PGVERSION'&total_ram='$AVAIL_MEMORY'MB' >> $TEMP_DIR/pg.conf
    # cat $TEMP_DIR/pg.conf | sudo tee -a /etc/postgresql/$PGVERSION/main/postgresql.conf

CURRENT_VER="11.2"

sudo apt-get update

sudo apt-get install make
mkdir pgbadger_install
cd pgbadger_install

#download from https://github.com/darold/pgbadger/releases
#NOTE: downloaded file name is not consistent - below will change name from v11.2.tar.gz to the proper name used below
#mv v$CURRENT_VER.tar.gz pgbadger-$CURRENT_VER.tar.gz

#installation instructions - https://github.com/darold/pgbadger#installation
tar xzf pgbadger-$CURRENT_VER.tar.gz
cd pgbadger-$CURRENT_VER/
perl Makefile.PL
make && sudo make install

#change if needed
OSUSER=ubuntu

sudo mkdir -p /var/reports/pgbadger/
sudo chown $OSUSER:$OSUSER /var/reports/pgbadger/

# verify installation
pgbadger --version

### Usage Recommendations ###
# single command - simple test and info
cd ~
mkdir -p deleteme_pgbadger/one-time/
cd deleteme_pgbadger/one-time/
pgbadger /var/log/postgresql/*
# this will produce an out.html. You can copy this file to your local machine to view the file through your browser

#add the following to cron to create an ongoing report
# 0 4 * * * /usr/local/bin/pgbadger -I -q /var/log/postgresql/* -O /var/reports/pgbadger/
# you can copy to your local maching using: 
# cd ~
# mkdir -p deleteme_pgbadger/incremental/
# cd deleteme_pgbadger/incremental/
# rsync -av --no-perms --no-owner --no-group $OSUSER@$YOUR_SERVER_IP:/var/reports/pgbadger/ .
# you can also update apache (already installed on db server) to show the report on a special port - instructions coming...
