require 'pact_broker/pacts/all_pacts'

module PactBroker
  module Pacts

    class LatestTaggedPacts < AllPacts
      set_dataset(:latest_tagged_pacts)
    end

  end
end
