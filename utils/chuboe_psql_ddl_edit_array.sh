#!/bin/bash

source chuboe.properties

#NOTE: you can create an array of dependent objects using this command:
#psql -c "begin; drop materialized view chuboe_adv_search_invoice_mv cascade; rollback;" 2>&1 | grep cascades |awk 'NR>1{print $(NF)}'

readarray -t ddl_array < $1

#check for empty string: -z checks for null
if [ -z "$ddl_array" ]; then
    echo "No input - you need to pass in a file containing export list"
    exit 1
fi

export_dir="ddl_export/"
mkdir -p $export_dir
export_file=$export_dir"ddl_export_"`date +%Y%m%d`_`date +%H%M%S`".sql"
echo See export file: $export_file

mkdir -p $export_dir

for i in "${ddl_array[@]}"
do
    echo --$i
    #echo pg_dump -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -h $CHUBOE_PROP_DB_HOST -t $i --schema-only
    pg_dump -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -h $CHUBOE_PROP_DB_HOST -t $i --schema-only >> $export_file
done
