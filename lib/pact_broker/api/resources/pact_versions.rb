require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/pact_versions_decorator'

module PactBroker
  module Api
    module Resources
      class PactVersions < BaseResource
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
          PactBroker::Api::Decorators::PactVersionsDecorator.new(pacts).to_json(user_options: decorator_context(identifier_from_path))
        end

        def pacts
          @pacts ||= pact_service.find_all_pact_versions_between consumer_name, :and => provider_name
        end

        def delete_resource
          pact_service.delete_all_pact_publications_between(consumer_name, and: provider_name)
          true
        end

        def policy_name
          :'pacts::pacts'
        end

        def policy_pacticipant
          consumer
        end
      end
    end
  end
end
