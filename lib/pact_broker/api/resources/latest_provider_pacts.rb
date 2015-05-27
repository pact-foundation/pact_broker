require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/provider_pacts_decorator'

module PactBroker
  module Api
    module Resources

      class LatestProviderPacts < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          pacticipant_service.find_pacticipant_by_name(provider_name)
        end

        def to_json
          PactBroker::Api::Decorators::ProviderPactsDecorator.new(pacts).to_json(decorator_context(identifier_from_path))
        end

        def pacts
          pact_service.find_latest_pact_versions_for_provider provider_name
        end

      end
    end
  end
end
