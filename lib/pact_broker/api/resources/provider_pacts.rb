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
          ["GET"]
        end

        def resource_exists?
          pacticipant_service.find_pacticipant_by_name(provider_name)
        end

        def to_json
          PactBroker::Api::Decorators::ProviderPactsDecorator.new(pacts).to_json(to_json_options)
        end

        private

        def pacts
          pact_service.find_pact_versions_for_provider provider_name, find_pact_options
        end

        def find_pact_options
          {
            tag: identifier_from_path[:tag],
            environment_name: identifier_from_path[:environment_name]
          }.reject{ |k, v| v.nil? }
        end

        def to_json_options
          {
            user_options: decorator_context(identifier_from_path.merge(title: resource_title))
          }
        end

        def resource_title
          suffix = if identifier_from_path[:tag]
            " with consumer version tag '#{identifier_from_path[:tag]}'"
          elsif identifier_from_path[:environment_name]
            " with consumers in the #{identifier_from_path[:environment_name]} environment"
          else
             ""
          end
          "All pact versions for the provider #{identifier_from_path[:provider_name]}#{suffix}"
        end
      end
    end
  end
end
