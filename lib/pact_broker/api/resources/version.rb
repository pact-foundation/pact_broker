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
          ["GET", "DELETE"]
        end

        def resource_exists?
          version
        end

        def to_json
          Decorators::VersionDecorator.new(version).to_json(user_options: {base_url: base_url})
        end

        def delete_resource
          version_service.delete version
          true
        end

        private

        def version
          if path_info[:tag]
            @version ||= version_service.find_by_pacticpant_name_and_latest_tag(path_info[:pacticipant_name], path_info[:tag])
          elsif path_info[:pacticipant_version_number]
            @version ||= version_service.find_by_pacticipant_name_and_number path_info
          else
            @version ||= version_service.find_latest_by_pacticpant_name path_info
          end
        end
      end
    end
  end
end
