require 'pact_broker/api/resources/base_resource'

module PactBroker::Api

  module Resources

    class Pacticipants < BaseResource

      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def allowed_methods
        ["GET"]
      end

      def to_json
        generate_json(pacticipant_service.find_all_pacticipants)
      end

      def generate_json pacticipants
        PactBroker::Api::Decorators::PacticipantCollectionRepresenter.new(pacticipants).to_json(base_url: resource_url)
      end

    end
  end

end
