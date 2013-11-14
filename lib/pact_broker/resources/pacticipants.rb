require 'webmachine'
require 'json'

require 'pact_broker/services'
require 'pact_broker/resources/json_resource'
require 'pact_broker/resources/base_url'
require 'pact_broker/api/decorators'

module PactBroker

  module Resources

    class Pacticipants < Webmachine::Resource

      include PactBroker::Services
      include PactBroker::Resources::PathInfo
      include PactBroker::Resources::BaseUrl

      def content_types_provided
        [["application/hal+json", :to_json]]
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
        PactBroker::Api::Decorators::PacticipantCollectionRepresenter.new(pacticipants, base_url).to_json
      end

    end
  end

end
