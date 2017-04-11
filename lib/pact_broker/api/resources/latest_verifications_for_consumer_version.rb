require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/domain/verification'
require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verifications_decorator'

module PactBroker
  module Api
    module Resources

      class LatestVerificationsForConsumerVersion < BaseResource

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          version_params = {pacticipant_name: identifier_from_path[:consumer_name], pacticipant_version_number: identifier_from_path[:consumer_version_number]}
          !!version_service.find_by_pacticipant_name_and_number(version_params)
        end

        def to_json
          verifications = verification_service.find_latest_verifications_for_consumer_version(identifier_from_path)
          decorator_for(verifications).to_json(user_options: decorator_context)
        end

        private

        def decorator_for verifications
          PactBroker::Api::Decorators::VerificationsDecorator.new(verifications)
        end
      end
    end
  end
end
