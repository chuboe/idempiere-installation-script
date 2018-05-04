pg_dump -U adempiere -d idempiere -t $1 --schema-only > ~/ddl_$1.sql
