require 'pact_broker/matrix/row'

module PactBroker
  module Matrix
    # A row for each of the overall latest pacts, and a row for each of the latest tagged pacts
    class HeadRow < Row
      set_dataset(:materialized_head_matrix)
    end
  end
end
