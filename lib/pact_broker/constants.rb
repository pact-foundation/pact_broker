module PactBroker
  module Constants
    CONSUMER_VERSION_HEADER = "X-Pact-Consumer-Version".freeze
    DO_NOT_ROLLBACK = "X-Pact-Broker-Do-Not-Rollback".freeze
  end

  # For backward compatibility, also expose at module level
  CONSUMER_VERSION_HEADER = Constants::CONSUMER_VERSION_HEADER
  DO_NOT_ROLLBACK = Constants::DO_NOT_ROLLBACK
end
