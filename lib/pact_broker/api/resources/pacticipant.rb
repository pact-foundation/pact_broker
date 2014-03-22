require 'pact_broker/api/resources/base_resource'

module Webmachine
  class Request
    def put?
      method == "PUT" || method == "PATCH"
    end
  end
end

module PactBroker::Api

  module Resources

    class Pacticipant < BaseResource

      def content_types_provided
        [["application/hal+json", :to_json]]
      end

      def content_types_accepted
        [["application/json", :from_json]]
      end

      def allowed_methods
        ["GET", "PATCH"]
      end

      def known_methods
        super + ['PATCH']
      end

      def from_json
        if @pacticipant
          @pacticipant = pacticipant_service.update params.merge(name: identifier_from_path[:name])
        else
          @pacticipant = pacticipant_service.create params.merge(name: identifier_from_path[:name])
          @created = true
        end
        response.body = to_json
      end

      def resource_exists?
        @pacticipant = pacticipant_service.find_pacticipant_by_name(identifier_from_path[:name])
        @pacticipant != nil
      end

      def finish_request
        response.code = 201 if @created
      end

      def to_json
        PactBroker::Api::Decorators::PacticipantRepresenter.new(@pacticipant).to_json(base_url: resource_url)
      end

    end
  end

end
