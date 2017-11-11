require 'pact_broker/api/resources/base_resource'

module Webmachine
  class Request
    def put?
      method == "PUT" || method == "PATCH"
    end
  end
end

module PactBroker
  module Api
    module Resources

      class Pacticipant < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PATCH", "DELETE"]
        end

        def known_methods
          super + ['PATCH']
        end

        def from_json
          if pacticipant
            @pacticipant = pacticipant_service.update params_with_string_keys.merge('name' => pacticipant_name)
          else
            @pacticipant = pacticipant_service.create params_with_string_keys.merge('name' => pacticipant_name)
            response.headers["Location"] = pacticipant_url(base_url, pacticipant)
          end
          response.body = to_json
        end

        def resource_exists?
          pacticipant
        end

        def delete_resource
          pacticipant_service.delete pacticipant_name
          true
        end

        def to_json
          PactBroker::Api::Decorators::PacticipantDecorator.new(pacticipant).to_json(user_options: { base_url: base_url })
        end

        private

        def pacticipant
          @pacticipant ||= pacticipant_service.find_pacticipant_by_name(pacticipant_name)
        end

        def pacticipant_name
          identifier_from_path[:name]
        end
      end
    end
  end
end
