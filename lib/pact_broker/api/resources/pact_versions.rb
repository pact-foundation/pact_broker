require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/pact_versions_decorator'

module PactBroker
  module Api
    module Resources

      class PactVersions < BaseResource

        def content_types_provided
          [["application/json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def to_json
          PactBroker::Api::Decorators::PactVersionsDecorator.new(pacts).to_json(decorator_context(identifier_from_path))
        end

        def pacts
          pact_service.find_all_pacts_between consumer_name, :and => provider_name
        end

      end
    end
  end
end
