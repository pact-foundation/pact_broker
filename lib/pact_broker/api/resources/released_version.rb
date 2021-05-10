require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/released_version_decorator'

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
          :'versions::versions'
        end

        # For PF
        def policy_record_context
          # Not sure whether the context should be empty or the pacticipant should be nil
          if released_version
            { pacticipant: released_version.pacticipant }
          else
            {}
          end
        end

        private

        attr_reader :released_version

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
