require "support/test_database"

PactBroker::Db.connection = PactBroker::TestDatabase.database = ::PactBroker::TestDatabase.connection_for_test_database

if !PactBroker::Db.is_current?(PactBroker::Db.connection)
  PactBroker::TestDatabase.migrate
end


# Forbid lazy loading for tests
# Gradually increase the models and associations that lazy loading is forbidden for
PactBroker::Pacts::PactPublication.plugin(:forbid_lazy_load)
#PactBroker::Domain::Version.plugin(:forbid_lazy_load) # Still working on this one
