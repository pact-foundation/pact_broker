require "fileutils"
require "logger"
require "sequel"
require "pact_broker"
require "pact_broker/api/middleware/basic_auth"
require "pact_broker/config/basic_auth_configuration"
require "pact_broker/api/authorization/resource_access_policy"
require "pact_broker/initializers/database_connection"

SemanticLogger.add_appender(io: $stdout)
SemanticLogger.default_level = :info
$logger  = SemanticLogger['pact-broker']

basic_auth_configuration = PactBroker::Config::BasicAuthRuntimeConfiguration.new
basic_auth_configuration.log_configuration($logger)

if basic_auth_configuration.use_basic_auth?
  policy = PactBroker::Api::Authorization::ResourceAccessPolicy.build(basic_auth_configuration.allow_public_read, basic_auth_configuration.public_heartbeat)
  use PactBroker::Api::Middleware::BasicAuth,
    basic_auth_configuration.write_credentials,
    basic_auth_configuration.read_credentials,
    policy
end

app = PactBroker::App.new do | config |
  config.database_connection = PactBroker.create_database_connection(config.logger, config.database_configuration, 0)
end

run app
