require "support/test_database"
require "pact_broker/db"

PactBroker::DB.connection = PactBroker::TestDatabase.database = ::PactBroker::TestDatabase.connection_for_test_database

if !PactBroker::DB.is_current?(PactBroker::DB.connection)
  PactBroker::TestDatabase.migrate
end

require "pact_broker/pacts/pact_publication"
require "pact_broker/domain/version"

# Forbid lazy loading for tests
# Gradually increase the models and associations that lazy loading is forbidden for
PactBroker::Pacts::PactPublication.plugin(:forbid_lazy_load)
#PactBroker::Domain::Version.plugin(:forbid_lazy_load) # Still working on this one
