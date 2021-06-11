require "pact_broker/api/resources/base_resource"
require "pact_broker/configuration"
require "pact_broker/domain/verification"
require "pact_broker/api/contracts/verification_contract"
require "pact_broker/api/decorators/verification_decorator"
require "pact_broker/api/decorators/extended_verification_decorator"

module PactBroker
  module Api
    module Resources
      class Verification < BaseResource
        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["application/json", :to_json],
            ["application/vnd.pactbrokerextended.v1+json", :to_extended_json]
          ]
        end

        # Remember to update latest_verification_id_for_pact_version_and_provider_version
        # if/when DELETE is implemented
        def allowed_methods
          ["GET", "OPTIONS", "DELETE"]
        end

        def resource_exists?
          if verification_number == "all"
            set_json_error_message("To see all the verifications for a pact, use the Matrix page")
            false
          elsif !verification_number_is_integer?
            false
          else
            !!verification
          end
        end

        def to_json
          decorator_for(verification).to_json(decorator_options)
        end

        def to_extended_json
          extended_decorator_for(verification).to_json(decorator_options)
        end

        def delete_resource
          verification_service.delete(verification)
          true
        end

        def policy_name
          :'verifications::verification'
        end

        def policy_pacticipant
          provider
        end

        private

        def verification
          @verification ||= verification_service.find(identifier_from_path)
        end

        def decorator_for model
          decorator_class(:verification_decorator).new(model)
        end

        def extended_decorator_for model
          decorator_class(:extended_verification_decorator).new(model)
        end

        def verification_number
          identifier_from_path[:verification_number]
        end

        def verification_number_is_integer?
          verification_number =~ /^\d+$/
        end
      end
    end
  end
end
