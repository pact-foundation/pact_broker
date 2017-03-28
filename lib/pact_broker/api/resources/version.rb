require 'pact_broker/services'
require 'pact_broker/api/decorators/version_decorator'

module PactBroker
  module Api
    module Resources

      class Version < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          version
        end

        def to_json
          Decorators::VersionDecorator.new(version).to_json(user_options: {base_url: base_url})
        end

        private

        def version
          @version ||= version_service.find_by_pacticipant_name_and_number path_info
        end

      end
    end

  end
end
