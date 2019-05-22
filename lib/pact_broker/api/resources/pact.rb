require 'cgi'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/pacticipant_resource_methods'
require 'pact_broker/api/decorators/pact_decorator'
require 'pact_broker/json'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/api/contracts/put_pact_params_contract'

module Webmachine
  class Request
    def patch?
      method == "PATCH"
    end
  end
end

module PactBroker

  module Api
    module Resources

      class Pact < BaseResource

        include PacticipantResourceMethods

        def content_types_provided
          [["application/hal+json", :to_json],
           ["application/json", :to_json],
           ["text/html", :to_html]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE", "PATCH", "OPTIONS"]
        end

        def known_methods
          super + ['PATCH']
        end

        def is_conflict?
          merge_conflict = request.patch? && resource_exists? &&
            Pacts::Merger.conflict?(pact.json_content, pact_params.json_content)

          potential_duplicate_pacticipants?(pact_params.pacticipant_names) || merge_conflict
        end

        def malformed_request?
          if request.patch? || request.put?
            invalid_json? ||
              contract_validation_errors?(Contracts::PutPactParamsContract.new(pact_params), pact_params)
          else
            false
          end
        end

        def resource_exists?
          !!pact
        end

        def from_json
          response_code = pact ? 200 : 201

          if request.patch? && resource_exists?
            @pact = pact_service.merge_pact(pact_params, webhook_options)
          else
            @pact = pact_service.create_or_update_pact(pact_params, webhook_options)
          end

          response.body = to_json
          response_code
        end

        def to_json
          PactBroker::Api::Decorators::PactDecorator.new(pact).to_json(user_options: decorator_context(metadata: identifier_from_path[:metadata]))
        end

        def to_html
          PactBroker.configuration.html_pact_renderer.call(
            pact, {
              base_url: base_url,
              badge_url: badge_url_for_latest_pact(pact, base_url)
          })
        end

        def delete_resource
          pact_service.delete(pact_params)
          set_post_deletion_response
          true
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def pact_params
          @pact_params ||= PactBroker::Pacts::PactParams.from_request request, path_info
        end

        def update_matrix_after_request?
          request.put? || request.patch?
        end

        def set_post_deletion_response
          latest_pact = pact_service.find_latest_pact(pact_params)
          response_body = { "_links" => {} }
          if latest_pact
            response_body["_links"]["pb:latest-pact-version"] = {
              href: latest_pact_url(base_url, latest_pact),
              title: "Latest pact"
            }
          end
          response.body = response_body.to_json
          response.headers["Content-Type" => "application/hal+json;charset=utf-8"]
        end

        def webhook_options
          {
            database_connector: database_connector,
            webhook_context: {
              base_url: base_url
            }
          }
        end
      end
    end
  end
end
