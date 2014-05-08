require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/relationships_csv_decorator'

module PactBroker::Api

  module Resources

    class Relationships < BaseResource

      def content_types_provided
        [["text/csv", :to_csv]]
      end

      def allowed_methods
        ["GET"]
      end

      def to_csv
        generate_csv(pact_service.find_latest_pacts)
      end

      def generate_csv pacts
        PactBroker::Api::Decorators::RelationshipsCsvDecorator.new(pacts).to_csv
      end

    end
  end

end
