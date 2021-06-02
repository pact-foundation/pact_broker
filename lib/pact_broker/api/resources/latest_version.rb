require "pact_broker/api/resources/version"

module PactBroker
  module Api
    module Resources
      class LatestVersion < Version
        def content_types_accepted
          []
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        private

        def version
          if identifier_from_path[:tag]
            @version ||= version_service.find_by_pacticipant_name_and_latest_tag(identifier_from_path[:pacticipant_name], identifier_from_path[:tag])
          else
            @version ||= version_service.find_latest_by_pacticpant_name(identifier_from_path)
          end
        end
      end
    end
  end
end
