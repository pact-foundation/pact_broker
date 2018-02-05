SCHEMA="pact_broker"
set -e
mysql mysql -h localhost -u root -e "select 'drop table "' || tablename || '" cascade;' from pg_tables;'"
mysql mysql -h localhost -u root -e 'CREATE DATABASE pact_broker;'
mysql mysql -h localhost -u root -e "GRANT ALL ON pact_broker.* TO 'pact_broker'@'%' identified by 'pact_broker';"

ip=$(ifconfig en0 | sed -n -e '/inet/s/.*inet \([0-9.]*\) netmask .*/\1/p')
echo ""
echo "run the following command to set your environment variables:"
echo "export PACT_BROKER_DATABASE_USERNAME=pact_broker"
echo "export PACT_BROKER_DATABASE_PASSWORD=pact_broker"
echo "export PACT_BROKER_DATABASE_NAME=${SCHEMA}"
echo "export PACT_BROKER_DATABASE_HOST=${ip}"
echo "To test:"
echo "mysql -upact_broker -ppact_broker -hlocalhost"

