require 'pact_broker/api/pact_broker_urls'

module PactBroker
  module UI
    module ViewModels
      class Relationship

        include PactBroker::Api::PactBrokerUrls

        def initialize relationship
          @relationship = relationship
        end

        def consumer_name
          @relationship.consumer.name
        end

        def provider_name
          @relationship.provider.name
        end

        def latest_pact_url
          "#{pactigration_base_url('', @relationship)}/latest"
        end

        def <=> other
          comp = consumer_name <=> other.consumer_name
          return comp unless comp == 0
          provider_name <=> other.provider_name
        end

      end
    end
  end
end