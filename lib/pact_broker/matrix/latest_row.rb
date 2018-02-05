require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    # Latest pact revision for each consumer version => latest verification for each provider version
    class LatestRow < Row
      set_dataset(:latest_matrix_for_consumer_version_and_provider_version)
    end
  end
end
