require 'pact_broker/matrix/row'

module PactBroker
  module Matrix

    # Latest pact revision for each consumer version => latest verification

    class LatestRow < Row
      set_dataset(:latest_matrix)
    end
  end
end
