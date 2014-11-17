require 'pact_broker/pacts/all_pacts'

module PactBroker
  module Pacts

    class LatestPacts < AllPacts
      set_dataset(:latest_pacts)
    end

  end
end
