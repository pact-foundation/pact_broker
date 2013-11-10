require 'webmachine'
require 'json'

require 'pact_broker/services'
require 'pact_broker/resources/json_resource'
require 'pact_broker/api/representors'

module PactBroker

  module Resources

    class Pacticipants < Webmachine::Resource

      include PactBroker::Services
      include PactBroker::Resources::PathInfo

      def content_types_provided
        [["application/json+hal", :to_json]]
      end

      def handle_exception e
        PactBroker::Resources::ErrorHandler.handle_exception(e, response)
      end

      def allowed_methods
        ["GET"]
      end

      def to_json
        generate_json(pacticipant_service.find_all_pacticipants)
      end

      def generate_json pacticipants
        pacticipants.extend(PactBroker::Api::Representors::PacticipantCollectionRepresenter)
        pacticipants.to_json
      end

    end
  end

end
