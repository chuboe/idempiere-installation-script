#!/bin/bash
#
#PURPOSE
#This is a cleanup script to remove delme artifacts.
#
#There are times when you should create a quick delme backup of data before you perform a dangerous operation.
#The use of "create table delme_some_table as select some_columns from some_table" just might save your job!
#
#There are times when it is helpful to create a delme temporary table or view to aid in data transformation.

source chuboe.properties

sql_view="select 'drop view ' || table_name || ';' from information_schema.tables where table_type = 'VIEW' and (table_name like 'delme%' or table_name like 'deleteme%');"
sql_table="select 'drop table ' || table_name || ';' from information_schema.tables where table_type = 'BASE TABLE' and (table_name like 'delme%' or table_name like 'deleteme%');"

view_list="/tmp/delme_view_statement.sql"
table_list="/tmp/delme_table_statement.sql"

view_list_out="/tmp/delme_view_statement.out"
table_list_out="/tmp/delme_table_statement.out"

#db_host=$CHUBOE_PROP_DB_HOST
echo "*************************************"
echo "DATABASE HOST - $CHUBOE_PROP_DB_HOST "
echo "DATABASE NAME - $CHUBOE_PROP_DB_NAME "
echo "*************************************"

echo $sql_view
psql -d $CHUBOE_PROP_DB_NAME -U $CHUBOE_PROP_DB_USERNAME -h $CHUBOE_PROP_DB_HOST -c "$sql_view" > $view_list
cat $view_list
echo '**********'
echo '**********'
read -p "Dangerous!!! Review the above list of views! Press enter if you wish to drop all of them. Otherwise, press ctrl+c to abort."
echo
echo
grep 'drop view' $view_list | psql -d $CHUBOE_PROP_DB_NAME -U $CHUBOE_PROP_DB_USERNAME -h $CHUBOE_PROP_DB_HOST &> $view_list_out
echo cat $view_list_out to see results.
echo
echo

echo $sql_table
psql -d $CHUBOE_PROP_DB_NAME -U $CHUBOE_PROP_DB_USERNAME -h $CHUBOE_PROP_DB_HOST -c "$sql_table" > $table_list
cat $table_list
echo '**********'
echo '**********'
read -p "Dangerous!!! Review the above list of tables! Press enter if you wish to drop all of them. Otherwise, press ctrl+c to abort."
echo
echo
grep 'drop table' $table_list | psql -d $CHUBOE_PROP_DB_NAME -U $CHUBOE_PROP_DB_USERNAME -h $CHUBOE_PROP_DB_HOST &> $table_list_out
echo cat $table_list_out to see results.
echo
echo
