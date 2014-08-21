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

        def to_csv
          generate_csv(group_service.find_group_containing @pacticipant)
        end

        def generate_csv group
          PactBroker::Api::Decorators::RelationshipsCsvDecorator.new(group).to_csv
        end

        def pacticipant_name
          identifier_from_path[:pacticipant_name]
        end

        def resource_exists?
          @pacticipant = pacticipant_service.find_pacticipant_by_name(pacticipant_name)
          @pacticipant != nil
        end

      end
    end

  end
end