#!/bin/bash

# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
. chuboe.properties

SCRIPTNAME=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPTNAME")
file=$SCRIPTPATH/chuboe.properties
. $file
echo "File path"$file
IDEMPIEREUSER=$CHUBOE_PROP_IDEMPIERE_OS_USER
PIP=$CHUBOE_PROP_DB_HOST
INSTALLPATH=$CHUBOE_PROP_METABASE_INSTALLATION_PATH
INITDNAME=$CHUBOE_PROP_IDEMPIERE_SERVICE_NAME
IDEMPIERE_DB_NAME=$CHUBOE_PROP_DB_NAME
IDEMPIERE_DB_USER=$CHUBOE_PROP_DB_USERNAME
DBPASS=$CHUBOE_PROP_DB_PASSWORD
METABASE_DB=$CHUBOE_PROP_METABASE_DB
METABASE_USER=$CHUBOE_PROP_METABASE_USER
METABASE_PASSWORD=$CHUBOE_PROP_METABASE_PASSWORD
METABASE_JAR_URL=$CHUBOE_PROP_METABASE_JAR_URL
echo "Installation directory "$INSTALLPATH
echo "Metabase .... starting installation "
echo "creating new mtabase directory"
sudo mkdir $INSTALLPATH
#sudo chown $IDEMPIEREUSER:$IDEMPIEREUSER $INSTALLPATH
sudo chmod -R go+w $INSTALLPATH
cd $INSTALLPATH
#sudo wget $METABASE_JAR_URL
METABASE=$INSTALLPATH/metabase.jar

sudo -u $IDEMPIEREUSER psql -h $PIP -U $IDEMPIERE_DB_USER -d $IDEMPIERE_DB_NAME -c "CREATE DATABASE "$METABASE_DB;
sudo -u $IDEMPIEREUSER psql -h $PIP -U $IDEMPIERE_DB_USER -d $IDEMPIERE_DB_NAME -c "CREATE USER "$METABASE_USER" WITH ENCRYPTED PASSWORD '"$METABASE_PASSWORD"'";
sudo -u $IDEMPIEREUSER psql -h $PIP -U $IDEMPIERE_DB_USER -d $IDEMPIERE_DB_NAME -c "GRANT ALL PRIVILEGES ON DATABASE "$METABASE_DB" TO "$METABASE_USER;

cat <<EOF >> mbase.sh
#!/bin/sh
export MB_DB_TYPE=postgres;
export MB_DB_DBNAME=$METABASE_DB;
export MB_DB_PORT=3000;
export MB_DB_USER=$CHUBOE_PROP_METABASE_USER;
export MB_DB_PASS=$CHUBOE_PROP_METABASE_PASSWORD;
export MB_DB_HOST=$PIP;
sudo java -jar $METABASE
EOF

sudo chmod +x mbase.sh

cd /etc/init.d/
cat <<EOF >> metabase
#!/bin/sh
# /etc/init.d/metabase
### BEGIN INIT INFO
# Provides:          Metabase
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Metabase analytics and intelligence platform
### END INIT INFO

# which (unprivileged) user should we run Metabase as?
RUNAS=$IDEMPIEREUSER

# where should we store the pid/log files?
PIDFILE=/var/run/metabase.pid
LOGFILE=/var/log/metabase.log

start() {
# ensure we only run 1 Metabase instance
if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE"); then
echo 'Metabase already running' >&2
return 1
fi
echo 'Starting Metabase...' >&2
# execute the Metabase jar and send output to our log
local CMD="nohup java -jar \"$METABASE\" &> \"$LOGFILE\" & echo \$!"
# load Metabase config before we start so our env vars are available
export MB_DB_TYPE=postgres;
export MB_DB_DBNAME=$METABASE_DB;
export MB_DB_PORT=3000;
export MB_DB_USER=$METABASE_USER;
export MB_DB_PASS=$METABASE_PASSWORD;
export MB_DB_HOST=0.0.0.0;
# run our Metabase cmd as unprivileged user
su -c "$CMD" $RUNAS > "$PIDFILE"
echo 'Metabase started.' >&2
}

stop() {
# ensure Metabase is running
if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
echo 'Metabase not running' >&2
return 1
fi
echo 'Stopping Metabase ...' >&2
# send Metabase TERM signal
kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
echo 'Metabase stopped.' >&2
}
case "$1" in
start)
start
;;
stop)
stop
;;
restart)
stop
start
;;
*)
echo "Usage: $0 {start|stop|restart}"
esac
EOF

sudo chmod +x /etc/init.d/metabase
sudo update-rc.d metabase defaults

echo "METABASE INSTALLATION COMPLETE, METABASE INSTALLATION PATH "$CHUBOE_PROP_METABASE_INSTALLATION_PATH
echo "To start the metabase issue command sudo ./metabase"

exit 0



#!/bin/bash

