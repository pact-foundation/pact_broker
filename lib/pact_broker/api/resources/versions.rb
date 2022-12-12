require "pact_broker/api/resources/base_resource"
require "pact_broker/configuration"
require "pact_broker/api/decorators/versions_decorator"

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
          decorator_class(:versions_decorator).new(versions).to_json(decorator_options(identifier_from_path))
        end

        def versions
          @versions ||= version_service.find_all_pacticipant_versions_in_reverse_order(pacticipant_name, pagination_options)
        end

        def policy_name
          :'versions::versions'
        end
      end
    end
  end
end
