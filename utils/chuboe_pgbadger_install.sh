# This is not a script yet!!! It is a collection of commands to run - a work in progress.
# This also has all my hours of troubleshooting notes

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
# note that ownership of this folder is confusing because of how pgbadger is run. 

# verify installation
pgbadger --version

### Ubuntu Considerations ###
# you might need this package to process logs maintained via csv:
    # sudo apt install libtext-csv-perl
    # this should be the same as installing the perl module: Text::CSV_XS
# postgresql maintains logs in two places (IMPORTANT!!!!):
    # startup logs appear here: /var/log/postgresql/*
    # the real logs appear here: /var/lib/postgresql/10/main/log/
    # note that /var/lib/postgresql/10/main/log/ is owned by postgres user. Sudo does not work well in this folder.

### Usage Recommendations ###
## single command - simple test and info
cd ~
mkdir -p deleteme_pgbadger/one-time/
cd deleteme_pgbadger/one-time/
sudo -u postgres pgbadger /var/lib/postgresql/10/main/log/*.csv
# this will produce an out.html. You can copy this file to your local machine to view the file through your browser

##add the following to cron to create an ongoing report
# note that sudo does not work well with this command. It produces the following error: FATAL: logfile "/var/lib/postgresql/10/main/log/*.csv" must exist!
# instead, you should use "sudo su" to run the below command
/usr/local/bin/pgbadger -I -q /var/lib/postgresql/10/main/log/*.csv -O /var/reports/pgbadger/
# 0 4 * * * /usr/local/bin/pgbadger -I -q /var/log/postgresql/* -O /var/reports/pgbadger/
# you can copy the results your local maching by issuing the following commands from your local machine:
# cd ~
# mkdir -p deleteme_pgbadger/incremental/
# cd deleteme_pgbadger/incremental/
# rsync -av --no-perms --no-owner --no-group $OSUSER@$YOUR_SERVER_IP:/var/reports/pgbadger/ .
# you can also update apache (already installed on db server) to show the report on a special port - instructions coming...
