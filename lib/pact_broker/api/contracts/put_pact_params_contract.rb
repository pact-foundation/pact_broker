require 'reform'
require 'reform/form'
require 'pact_broker/messages'
require 'pact_broker/constants'
require 'pact_broker/api/contracts/pacticipant_name_contract'
require 'pact_broker/api/contracts/consumer_version_number_validation'

module PactBroker
  module Api
    module Contracts
      class PutPacticipantNameContract < PacticipantNameContract
        validation do
          required(:name).filled
        end
        # validate :name_in_path_matches_name_in_pact

        def name_in_path_matches_name_in_pact
          if present?(name) && present?(name_in_pact)
            if name != name_in_pact
              errors.add(:name, validation_message('pacticipant_name_mismatch', message_args))
            end
          end
        end

        def present? string
          string && !blank?(string)
        end

      end

      class PutPactParamsContract < Reform::Form
        include PactBroker::Messages

        property :consumer_version_number
        property :consumer, form: PutPacticipantNameContract
        property :provider, form: PutPacticipantNameContract

        # validates :consumer_version_number, presence: true
        # validate :consumer_version_number_valid

        include ConsumerVersionNumberValidation

        def consumer_version_number_validation_message
          validation_message('consumer_version_number_invalid', consumer_version_number: consumer_version_number)
        end
      end
    end
  end
end
