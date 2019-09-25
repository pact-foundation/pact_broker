require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/domain/verification'
require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verification_decorator'
require 'pact_broker/api/decorators/extended_verification_decorator'

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
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!verification
        end

        def to_json
          decorator_for(verification).to_json(user_options: {base_url: base_url})
        end

        def to_extended_json
          extended_decorator_for(verification).to_json(user_options: {base_url: base_url})
        end

        private

        def verification
          @verification ||= verification_service.find(identifier_from_path)
        end

        def decorator_for model
          PactBroker::Api::Decorators::VerificationDecorator.new(model)
        end

        def extended_decorator_for model
          PactBroker::Api::Decorators::ExtendedVerificationDecorator.new(model)
        end
      end
    end
  end
end
