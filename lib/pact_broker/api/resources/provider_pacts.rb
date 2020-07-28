require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/provider_pacts_decorator'

module PactBroker
  module Api
    module Resources
      class ProviderPacts < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!provider
        end

        def policy_name
          :'pacts:provider_pacts'
        end

        def policy_record
          provider
        end

        def to_json
          PactBroker::Api::Decorators::ProviderPactsDecorator.new(pacts).to_json(to_json_options)
        end

        private

        def pacts
          pact_service.find_pact_versions_for_provider provider_name, tag: identifier_from_path[:tag]
        end

        def to_json_options
          {
            user_options: decorator_context(identifier_from_path.merge(title: resource_title))
          }
        end

        def resource_title
          suffix = identifier_from_path[:tag] ? " with consumer version tag '#{identifier_from_path[:tag]}'" : ""
          "All pact versions for the provider #{identifier_from_path[:provider_name]}#{suffix}"
        end
      end
    end
  end
end
