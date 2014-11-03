require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'

module PactBroker
  module UI
    module ViewDomain
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

        def consumer_group_url
          Helpers::URLHelper.group_url consumer_name
        end

        def provider_group_url
          Helpers::URLHelper.group_url provider_name
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