require 'pact_broker/pacts/all_pact_publications'

module PactBroker
  module Pacts

    # See /DEVELOPER_DOCUMENTATION.md for all_pacts view
    class AllPacts < AllPactPublications
      set_dataset(:all_pacts)
    end

  end
end
