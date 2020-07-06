require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/domain/verification'
require 'pact_broker/api/contracts/verification_contract'
require 'pact_broker/api/decorators/verification_summary_decorator'

module PactBroker
  module Api
    module Resources
      class LatestVerificationsForConsumerVersion < BaseResource

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def resource_exists?
          !!version
        end

        def to_json
          summary = verification_service.verification_summary_for_consumer_version(identifier_from_path)
          decorator_for(summary).to_json(user_options: decorator_context(identifier_from_path))
        end

        private

        def version
          version_service.find_by_pacticipant_name_and_number(
            pacticipant_name: consumer_name,
            pacticipant_version_number: consumer_version_number
          )
        end

        def decorator_for summary
          PactBroker::Api::Decorators::VerificationSummaryDecorator.new(summary)
        end
      end
    end
  end
end
