# docker run -p "5433:5432" --cpus 0.2 postgres:9.5-alpine

SCHEMA="pact_broker"
set +e
export PACT_BROKER_DATABASE_HOST="127.0.0.1"
export PACT_BROKER_DATABASE_PORT="5433"
psql postgres -h $PACT_BROKER_DATABASE_HOST -p $PACT_BROKER_DATABASE_PORT -U postgres -c "DROP DATABASE ${SCHEMA};"
psql postgres -h $PACT_BROKER_DATABASE_HOST -p $PACT_BROKER_DATABASE_PORT -U postgres -c "CREATE DATABASE ${SCHEMA};"
psql postgres -h $PACT_BROKER_DATABASE_HOST -p $PACT_BROKER_DATABASE_PORT -U postgres -c "CREATE USER pact_broker WITH PASSWORD 'pact_broker'"
psql postgres -h $PACT_BROKER_DATABASE_HOST -p $PACT_BROKER_DATABASE_PORT -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${SCHEMA} to pact_broker;"
psql postgres -h $PACT_BROKER_DATABASE_HOST -p $PACT_BROKER_DATABASE_PORT -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${SCHEMA} TO pact_broker;"
echo ""
echo "run the following command to set your environment variables:"
echo "export PACT_BROKER_DATABASE_USERNAME=pact_broker"
echo "export PACT_BROKER_DATABASE_PASSWORD=pact_broker"
echo "export PACT_BROKER_DATABASE_NAME=${SCHEMA}"
echo "export PACT_BROKER_DATABASE_HOST=${ip}"
echo "export PACT_BROKER_DATABASE_PORT=${PACT_BROKER_DATABASE_PORT}"
echo "To test:"
echo 'psql -h $PACT_BROKER_DATABASE_HOST -p $PACT_BROKER_DATABASE_PORT -d $PACT_BROKER_DATABASE_NAME -U $PACT_BROKER_DATABASE_USERNAME'
