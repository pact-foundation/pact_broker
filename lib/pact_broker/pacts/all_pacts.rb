require 'pact_broker/pacts/all_pact_revisions'

module PactBroker
  module Pacts

    class AllPacts < AllPactRevisions
      set_dataset(:all_pacts)
    end

  end
end
