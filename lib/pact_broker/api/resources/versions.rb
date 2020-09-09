require 'pact_broker/api/resources/base_resource'
require 'pact_broker/configuration'
require 'pact_broker/api/decorators/versions_decorator'

module PactBroker
  module Api
    module Resources
      class Versions < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!pacticipant
        end

        def to_json
          PactBroker::Api::Decorators::VersionsDecorator.new(versions).to_json(user_options: decorator_context(identifier_from_path))
        end

        def versions
          @versions ||= pacticipant_service.find_all_pacticipant_versions_in_reverse_order pacticipant_name
        end

        def policy_name
          :'versions::versions'
        end
      end
    end
  end
end
