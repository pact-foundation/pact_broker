require 'pact_broker/pacts/all_pact_publications'

module PactBroker
  module Pacts

    class AllPacts < AllPactPublications
      set_dataset(:all_pacts)
    end

  end
end
