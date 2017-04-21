require 'pact_broker/pacts/all_pacts'

module PactBroker
  module Pacts

    # See /DEVELOPER_DOCUMENTATION.md for latest_pacts view
    class LatestPacts < AllPacts
      set_dataset(:latest_pacts)
    end

  end
end
