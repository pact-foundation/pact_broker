require 'reform'
require 'reform/contract'
require 'versionomy'
require 'pact_broker/messages'
require 'pact_broker/constants'

module PactBroker
  module Api
    module Contracts

      class PostPactParamsContract < Reform::Contract

        include PactBroker::Messages

        property :consumer_name
        property :provider_name
        property :consumer_version_number

        validate :consumer_version_number_present
        validate :consumer_version_number_valid
        validate :consumer_name_not_blank
        validate :consumer_name_present
        validate :provider_name_not_blank
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

        def consumer_name_present
          unless consumer_name
            errors.add(:'pact.consumer.name', validation_message('pact_missing_pacticipant_name', pacticipant: 'consumer'))
          end
        end

        def provider_name_present
          unless provider_name
            errors.add(:'pact.provider.name', validation_message('pact_missing_pacticipant_name', pacticipant: 'provider'))
          end
        end

        def consumer_name_not_blank
          if blank? consumer_name
            errors.add(:'pact.consumer.name', validation_message('blank'))
          end
        end

        def blank? string
          string && string.strip.empty?
        end

        def empty? string
          string.nil? || blank?(string)
        end

        def provider_name_not_blank
          if blank? provider_name
            errors.add(:'pact.provider.name', validation_message('blank'))
          end
        end

        def consumer_version_number_validation_message
          validation_message('consumer_version_number_invalid', consumer_version_number: consumer_version_number)
        end
      end
    end
  end
end
