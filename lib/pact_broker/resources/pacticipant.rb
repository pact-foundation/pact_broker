require 'webmachine'
require 'json'
require 'cgi'

require 'pact_broker/services'
require 'pact_broker/resources/json_resource'
require 'pact_broker/api/representors'

module PactBroker

  module Resources

    class Pacticipant < Webmachine::Resource

      include PactBroker::Services
      include PactBroker::Resources::PathInfo

      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def handle_exception e
        PactBroker::Resources::ErrorHandler.handle_exception(e, response)
      end

      def allowed_methods
        ["GET", "PATCH"]
      end

      def known_methods
        super + ['PATCH']
      end

      def from_json
        pacticipant, created = pacticipant_service.create_or_update_pacticipant(
          name: identifier_from_path[:name],
          repository_url: params[:repository_url]
        )
        @manual_response_code = 201 if created
        response.body = generate_json(pacticipant)
      end

      def finish_request
        if @manual_response_code
          response.code = @manual_response_code
        end
      end

      def resource_exists?
        #Terrible hack to allow Webmachine to continue when a PATCH is used - does not seem to support it
        if request.method == 'PATCH'
          def request.method
            'PUT'
          end
        end
        @pacticipant = pacticipant_service.find_pacticipant_by_name(identifier_from_path[:name])
        @pacticipant != nil
      end

      def to_json
        generate_json(@pacticipant)
      end

      def generate_json pacticipant
        PactBroker::Api::Representors::PacticipantRepresenter.new(pacticipant).to_json
      end

      def params
        JSON.parse(request.body.to_s)
      end

    end
  end

end
