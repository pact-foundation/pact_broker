require 'pact_broker/pacts/all_pact_publications'

module PactBroker
  module Pacts

    class LatestPactPublicationsByConsumerVersion < AllPactPublications
      set_dataset(:latest_pact_publications_by_consumer_versions)
    end

  end
end
