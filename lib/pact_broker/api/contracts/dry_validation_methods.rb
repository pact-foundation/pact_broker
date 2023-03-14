require "pact_broker/api/contracts/validation_helpers"

module PactBroker
  module Api
    module Contracts
      module DryValidationMethods
        extend self

        def validation_message(key, params = {})
          PactBroker::Messages.validation_message(key, params)
        end

        def provided?(value)
          ValidationHelpers.provided?(value)
        end

        def not_provided?(value)
          ValidationHelpers.not_provided?(value)
        end

        def validate_version_number(value, key)
          if !PactBroker::Api::Contracts::ValidationHelpers.valid_version_number?(value)
            key.failure(PactBroker::Messages.validation_message("invalid_version_number", value: value))
          end
        end

        def validate_url(value, key)
          if PactBroker::Api::Contracts::ValidationHelpers.valid_url?(value)
            key.failure(PactBroker::Messages.validation_message("invalid_url"))
          end
        end

        def validate_pacticipant_with_name_exists(value, key)
          if ValidationHelpers.provided?(value) && !ValidationHelpers.pacticipant_with_name_exists?(value)
            key.failure(PactBroker::Messages.validation_message("pacticipant_with_name_not_found"))
          end
        end

        def validate_environment_with_name_exists(value, key)
          if ValidationHelpers.provided?(value) && !ValidationHelpers.environment_with_name_exists?(value)
            key.failure(PactBroker::Messages.validation_message("environment_not_found", value: value))
          end
        end

        def validate_not_blank_if_present(value, key)
          if value && ValidationHelpers.blank?(value)
            key.failure(PactBroker::Messages.validation_message("blank"))
          end
        end

        def validate_no_spaces_if_present(value, key)
          if value && ValidationHelpers.includes_space?(value)
            key.failure(PactBroker::Messages.validation_message("no_spaces"))
          end
        end

        def validate_not_multiple_lines(value, key)
          if value && ValidationHelpers.multiple_lines?(value)
            key.failure(PactBroker::Messages.validation_message("single_line"))
          end
        end

        def validate_valid_url(value, key)
          if value && !ValidationHelpers.valid_url?(value)
            key.failure(PactBroker::Messages.validation_message("invalid_url"))
          end
        end
      end
    end
  end
end
