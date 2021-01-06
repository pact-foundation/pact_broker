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
          PactBroker::Api::Decorators::VersionsDecorator.new(versions).to_json(decorator_options(identifier_from_path))
        end

        def versions
          @versions ||= pacticipant_service.find_all_pacticipant_versions_in_reverse_order(pacticipant_name, pagination_options)
        end

        def policy_name
          :'versions::versions'
        end

        def pagination_options
          if request.query['pageNumber'] || request.query['pageSize']
            {
              page_number: request.query['pageNumber']&.to_i || 1,
              page_size: request.query['pageSize']&.to_i || 100
            }
          else
            nil
          end
        end
      end
    end
  end
end
