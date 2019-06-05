# import
echo "Importing database from ${export_file}"
script/recreate-pg-db.sh
local_connection_string="postgresql://pact_broker:pact_broker@localhost/pact_broker"
psql $local_connection_string < "$1"
