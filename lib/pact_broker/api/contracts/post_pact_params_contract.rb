require 'reform'
require 'reform/contract'
require 'versionomy'
require 'pact_broker/messages'
require 'pact_broker/constants'
require 'pact_broker/api/contracts/pacticipant_name_validation'
require 'pact_broker/api/contracts/pacticipant_name_contract'
require 'pact_broker/api/contracts/consumer_version_number_validation'

module PactBroker
  module Api
    module Contracts

      class PostPacticipantNameContract < PacticipantNameContract

        validate :name_in_pact_present
        validates :name_in_pact, blank: false

        def name_in_pact_present
          unless name_in_pact
            errors.add(:'name', validation_message('pact_missing_pacticipant_name', pacticipant: pacticipant))
          end
        end
      end

      class PostPactParamsContract < Reform::Contract

        include PactBroker::Messages

        property :consumer_version_number

        validate :consumer_version_number_present
        validate :consumer_version_number_valid

        property :consumer, form: PostPacticipantNameContract
        property :provider, form: PostPacticipantNameContract

        include ConsumerVersionNumberValidation

        def consumer_version_number_validation_message
          validation_message('consumer_version_number_header_invalid', consumer_version_number: consumer_version_number)
        end
      end
    end
  end
end
