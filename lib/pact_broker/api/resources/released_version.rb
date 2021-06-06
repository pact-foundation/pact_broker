require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/released_version_decorator"

module PactBroker
  module Api
    module Resources
      class ReleasedVersion < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!released_version
        end

        def to_json
          decorator_class(:released_version_decorator).new(released_version).to_json(decorator_options)
        end

        def policy_name
          :'versions::version'
        end

        def policy_record
          released_version&.version
        end

        private

        def released_version
          @released_version ||= released_version_service.find_by_uuid(uuid)
        end

        def uuid
          identifier_from_path[:uuid]
        end
      end
    end
  end
end
