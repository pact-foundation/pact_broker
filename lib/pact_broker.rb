require "pact_broker/version"
require "pact_broker/logging"
require "pact_broker/app"
require "pact_broker/db/log_quietener"
require "request_store"
require "pact_broker/configuration"

module PactBroker
  def self.configuration
    RequestStore.store[:pact_broker_configuration] ||= Configuration.default_configuration
  end

  def self.set_configuration(configuration)
    RequestStore.store[:pact_broker_configuration] = configuration
  end

  # @private, for testing only
  def self.reset_configuration
    RequestStore.store[:pact_broker_configuration] = Configuration.default_configuration
  end
end
