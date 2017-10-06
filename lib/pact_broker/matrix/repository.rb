require 'pact_broker/repositories/helpers'

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories::Helpers

      def find consumer_name, provider_name
        PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .left_outer_join(:latest_verifications, pact_version_id: :pact_version_id)
          .consumer(consumer_name)
          .provider(provider_name)
          .reverse(:consumer_version_order)
          .all
          .collect(&:values)
      end
    end
  end
end
