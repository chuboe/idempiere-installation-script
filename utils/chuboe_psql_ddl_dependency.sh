#create a file of dependent objects

source chuboe.properties

#check for empty string: -z checks for null
if [ -z "$1" ]; then
    echo "No input - you need to pass in the name of a ddl object"
    exit 1
fi

export_dir="ddl_dependent/"
export_file=$export_dir"ddl_"$1"_export_"`date +%Y%m%d`_`date +%H%M%S`".txt"
echo $export_file

mkdir -p $export_dir

psql -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -h $CHUBOE_PROP_DB_HOST -c "begin; drop materialized view $1 cascade; rollback;" 2>&1 | grep cascades | awk 'NR>1{print $(NF)}' > $export_file
