# This is not a script yet!!! It is a collection of commands to run - a work in progress.

# pgbadger anazlyses postgresql logs - http://dalibo.github.io/pgbadger/
# Note: the ubuntu version through apt-get is old (v3)

CURRENT_VER="7.0"

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

# 0 4 * * * /usr/bin/pgbadger -I -q /var/log/postgresql/postgresql.log.1 -O /var/reports/pgbadger/

