require 'reform'
require 'reform/contract'
require 'versionomy'
require 'pact_broker/messages'
require 'pact_broker/constants'
require 'pact_broker/api/contracts/pacticipant_name_validation'

module PactBroker
  module Api
    module Contracts

      class PostPactParamsContract < Reform::Contract

        include PactBroker::Messages

        property :consumer_version_number

        validate :consumer_version_number_present
        validate :consumer_version_number_valid

        property :consumer do

          property :name
          property :name_in_pact
          property :pacticipant
          property :to_h

          validate :name_present
          validate :name_not_blank

          include PacticipantNameValidation

        end

        property :provider do

          property :name
          property :name_in_pact
          property :pacticipant
          property :to_h

          validate :name_present
          validate :name_not_blank

          include PacticipantNameValidation

        end


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

        def consumer_version_number_validation_message
          validation_message('consumer_version_number_invalid', consumer_version_number: consumer_version_number)
        end

      end
    end
  end
end
