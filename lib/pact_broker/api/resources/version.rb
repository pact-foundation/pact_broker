require 'pact_broker/services'
require 'pact_broker/api/decorators/version_decorator'
require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      class Version < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!version
        end

        def to_json
          decorator_class(:version_decorator).new(version).to_json(decorator_options)
        end

        def delete_resource
          version_service.delete version
          true
        end

        def policy_name
          :'versions::version'
        end

        private

        def version
          if identifier_from_path[:tag]
            @version ||= version_service.find_by_pacticipant_name_and_latest_tag(identifier_from_path[:pacticipant_name], identifier_from_path[:tag])
          elsif identifier_from_path[:pacticipant_version_number]
            @version ||= version_service.find_by_pacticipant_name_and_number(identifier_from_path)
          else
            @version ||= version_service.find_latest_by_pacticpant_name(identifier_from_path)
          end
        end
      end
    end
  end
end
