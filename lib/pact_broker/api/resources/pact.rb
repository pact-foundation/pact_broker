require 'cgi'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/pacticipant_resource_methods'
require 'pact_broker/api/decorators/pact_decorator'
require 'pact_broker/json'

module PactBroker

  module Api
    module Resources

      class Pact < BaseResource

        include PacticipantResourceMethods

        def content_types_provided
          [["application/json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT"]
        end

        def malformed_request?
          if request.put?
            return invalid_json? ||
              potential_duplicate_pacticipants?([identifier_from_path[:consumer_name], identifier_from_path[:provider_name]])
          else
            false
          end
        end

        def resource_exists?
          pact
        end

        def from_json
          @pact, created = pact_service.create_or_update_pact(identifier_from_path.merge(:json_content => request_body))
          response.headers["Location"] = pact_url(base_url, pact) if created # Setting Location header causes a 201
          response.body = to_json
        end

        def to_json
          PactBroker::Api::Decorators::PactDecorator.new(pact).to_json(base_url: base_url)
        end

        def pact
          @pact ||= pact_service.find_pact(identifier_from_path)
        end

      end
    end
  end
end