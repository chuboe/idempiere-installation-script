# extract schema only definitions. This is useful when you need to edit objects like functions where many UI do not work as expected.

source chuboe.properties

#check for empty string: -z checks for null
if [ -z "$1" ]; then
    echo "No input - you need to pass in the name of a ddl object"
    exit 1
fi

export_dir="ddl_export/"
export_file=$export_dir"ddl_"$1"_export_"`date +%Y%m%d`_`date +%H%M%S`".sql"
echo See export file: $export_file

mkdir -p $export_dir

pg_dump -U $CHUBOE_PROP_DB_USERNAME -d $CHUBOE_PROP_DB_NAME -h $CHUBOE_PROP_DB_HOST -t $1 --schema-only > $export_file
