require 'reform'
require 'reform/contract'
require 'versionomy'
require 'pact_broker/messages'
require 'pact_broker/constants'

module PactBroker
  module Api
    module Contracts

      class CreatePactRequestContract < Reform::Contract

        include PactBroker::Messages

        property :headers
        property :body

        validate :consumer_version_number_present
        validate :consumer_version_number_valid
        validate :consumer_name_present
        validate :provider_name_present

        def consumer_version_number_present
          unless consumer_version_number
            errors.add(:base, validation_message('consumer_version_number_missing'))
          end
        end

        def consumer_version_number_valid
          if consumer_version_number && invalid_consumer_version_number?
            errors.add(:base, consumer_version_number_validation_message)
          end
        end

        def invalid_consumer_version_number?
          begin
            Versionomy.parse(consumer_version_number)
            false
          rescue Versionomy::Errors::ParseError => e
            true
          end
        end

        def consumer_version_number
          headers[CONSUMER_VERSION_HEADER]
        end

        def consumer_name_present
          unless consumer_name
            errors.add(:'pact.consumer.name', validation_message('pact_missing_consumer_name'))
          end
        end

        def provider_name_present
          unless provider_name
            errors.add(:'pact.provider.name', validation_message('pact_missing_provider_name'))
          end
        end

        def consumer_name
          pact_hash.fetch('consumer', {})['name']
        end

        def provider_name
          pact_hash.fetch('provider', {})['name']
        end

        def pact_hash
          @pact_hash = JSON.parse(body.to_s, PACT_PARSING_OPTIONS)
        end

        def consumer_version_number_validation_message
          validation_message('consumer_version_number_invalid', consumer_version_number: consumer_version_number)
        end
      end
    end
  end
end
