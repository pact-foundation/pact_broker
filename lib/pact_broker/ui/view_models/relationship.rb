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
          @relationship.consumer_name
        end

        def provider_name
          @relationship.provider_name
        end

        def latest_pact_url
          "#{pactigration_base_url('', @relationship)}/latest"
        end

        def <=> other
          comp = consumer_name.downcase <=> other.consumer_name.downcase
          return comp unless comp == 0
          provider_name.downcase <=> other.provider_name.downcase
        end

      end
    end
  end
end