require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/relationships_csv_decorator'

module PactBroker

  module Api
    module Resources

      class Group < BaseResource

        def content_types_provided
          [["text/csv", :to_csv]]
        end

        def allowed_methods
          ["GET"]
        end

        def resource_exists?
          pacticipant
        end

        def to_csv
          PactBroker::Api::Decorators::RelationshipsCsvDecorator.new(group).to_csv
        end

        private

        def pacticipant_name
          identifier_from_path[:pacticipant_name]
        end

        def pacticipant
          @pacticipant ||= pacticipant_service.find_pacticipant_by_name(pacticipant_name)
        end

        def group
          @group ||= group_service.find_group_containing pacticipant
        end

      end
    end

  end
end