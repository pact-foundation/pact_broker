require 'pact_broker/pacts/latest_pact_publications_by_consumer_version'

module PactBroker
  module Pacts

    class LatestPactPublications < LatestPactPublicationsByConsumerVersion
      set_dataset(:latest_pact_publications)
    end

  end
end
