require 'pact_broker/pacts/latest_pact_publications_by_consumer_version'

module PactBroker
  module Pacts

    class LatestTaggedPactPublications < LatestPactPublicationsByConsumerVersion
      set_dataset(:latest_tagged_pact_publications)
    end

  end
end
