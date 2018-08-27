require 'pact_broker/domain/version'

module PactBroker
  module Versions
    include PactBroker::Repositories::Helpers

    class LatestVersion < PactBroker::Domain::Version
      set_dataset(:latest_versions)
    end
  end
end
