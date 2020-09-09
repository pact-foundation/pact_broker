require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/tagged_pact_versions_decorator'

module PactBroker
  module Api
    module Resources
      class TaggedPactVersions < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          consumer && provider
        end

        def to_json
          PactBroker::Api::Decorators::TaggedPactVersionsDecorator.new(pacts).to_json(user_options: decorator_context(identifier_from_path))
        end

        def delete_resource
          pact_service.delete_all_pact_publications_between consumer_name, and: provider_name, tag: identifier_from_path[:tag]
          true
        end

        def pacts
          @pacts ||= pact_service.find_all_pact_versions_between consumer_name, and: provider_name, tag: identifier_from_path[:tag]
        end

        def policy_name
          :'pact::pacts'
        end
      end
    end
  end
end
