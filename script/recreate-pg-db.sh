psql postgres -c "drop database pact_broker;"
psql postgres -c "create database pact_broker;"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker to pact_broker;"
ip=$(ifconfig en0 | sed -n -e '/inet/s/.*inet \([0-9.]*\) netmask .*/\1/p')
echo ""
echo "run the following command to set your environment variables:"
echo "export PACT_BROKER_DATABASE_HOST=${ip}"
