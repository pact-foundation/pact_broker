require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'

module PactBroker
  module UI
    module ViewDomain
      class MatrixLine

        include PactBroker::Api::PactBrokerUrls

        def initialize line
          @line = line
        end

        def consumer_version_number
          @line[:consumer_version_number]
        end

        def provider_version_number
          @line[:provider_version]
        end

        def verification_status
          case @line[:success]
            when true then "Verified"
            when false then "Failed"
            else ''
          end
        end

        def verification_status_class
          case @line[:success]
            when true then 'success'
            when false then 'danger'
            else ''
          end
        end
      end
    end
  end
end