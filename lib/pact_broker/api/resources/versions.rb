require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/versions_decorator'

module PactBroker
  module Api
    module Resources

      class Versions < BaseResource

        def content_types_provided
          [["application/json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          pacticipant_service.find_pacticipant_by_name(pacticipant_name)
        end

        def to_json
          PactBroker::Api::Decorators::VersionsDecorator.new(versions).to_json(decorator_context(identifier_from_path))
        end

        def versions
          pacticipant_service.find_all_pacticipant_versions pacticipant_name
        end

      end
    end
  end
end
