SCHEMA="pact_broker"
set +e
psql postgres -c "DROP DATABASE ${SCHEMA};"
psql postgres -c "CREATE DATABASE ${SCHEMA};"
psql postgres -c "CREATE USER pact_broker WITH PASSWORD 'pact_broker'"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker;"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${SCHEMA} TO pact_broker;"
ip=$(ifconfig en0 | sed -n -e '/inet/s/.*inet \([0-9.]*\) netmask .*/\1/p')
echo ""
echo "run the following command to set your environment variables:"
echo "export PACT_BROKER_DATABASE_USERNAME=pact_broker"
echo "export PACT_BROKER_DATABASE_PASSWORD=pact_broker"
echo "export PACT_BROKER_DATABASE_NAME=${SCHEMA}"
echo "export PACT_BROKER_DATABASE_HOST=${ip}"
echo "To test:"
echo 'psql -h $PACT_BROKER_DATABASE_HOST -d $PACT_BROKER_DATABASE_NAME -U $PACT_BROKER_DATABASE_USERNAME'
