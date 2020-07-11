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
          ["GET", "PATCH", "DELETE", "OPTIONS"]
        end

        def known_methods
          super + ['PATCH']
        end

        def from_json
          if pacticipant
            @pacticipant = pacticipant_service.update params(symbolize_names: false).merge('name' => pacticipant_name)
          else
            @pacticipant = pacticipant_service.create params.merge(:name => pacticipant_name)
            response.headers["Location"] = pacticipant_url(base_url, pacticipant)
          end
          response.body = to_json
        end

        def resource_exists?
          !!resource
        end

        def resource
          pacticipant
        end

        def delete_resource
          pacticipant_service.delete(pacticipant_name)
          true
        end

        def to_json
          PactBroker::Api::Decorators::PacticipantDecorator.new(pacticipant).to_json(user_options: { base_url: base_url })
        end
      end
    end
  end
end
