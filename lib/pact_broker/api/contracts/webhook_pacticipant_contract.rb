require "dry-validation"
require "pact_broker/api/contracts/dry_validation_macros"
require "pact_broker/api/contracts/validation_helpers"

module PactBroker
  module Api
    module Contracts
      class WebhookPacticipantContract < ::Dry::Validation::Contract
        Helper = PactBroker::Api::Contracts::ValidationHelpers
        include PactBroker::Api::Contracts::DryValidationMethods

        json do
          optional(:name).maybe(:string)
          optional(:label).maybe(:string)
        end

        register_macro(:name_or_label_required) do
          if !Helper.provided?(values[:name]) && !Helper.provided?(values[:label])
            key(path.keys).failure(validation_message("blank"))
          end
        end

        register_macro(:name_and_label_exclusive) do
          if Helper.provided?(values[:name]) && Helper.provided?(values[:label])
            key([:label]).failure(validation_message("cannot_be_provided_at_same_time", name_1: "name", name_2: "label"))
          end
        end

        rule(:name, :label).validate(:name_or_label_required)
        rule(:name, :label).validate(:name_and_label_exclusive)

        rule(:name) do
          validate_pacticipant_with_name_exists(value, key) if Helper.provided?(value)
        end
      end
    end
  end
end
