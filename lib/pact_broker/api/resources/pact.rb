require 'cgi'
require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/pacticipant_resource_methods'
require 'pact_broker/api/decorators/pact_decorator'
require 'pact_broker/api/decorators/extended_pact_decorator'
require 'pact_broker/json'
require 'pact_broker/pacts/pact_params'
require 'pact_broker/api/contracts/put_pact_params_contract'
require 'pact_broker/webhooks/execution_configuration'
require 'pact_broker/api/resources/webhook_execution_methods'

module PactBroker
  module Api
    module Resources
      class Pact < BaseResource
        include PacticipantResourceMethods
        include WebhookExecutionMethods

        def content_types_provided
          [
            ["application/hal+json", :to_json],
            ["application/json", :to_json],
            ["text/html", :to_html],
            ["application/vnd.pactbrokerextended.v1+json", :to_extended_json]
          ]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE", "PATCH", "OPTIONS"]
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
          !!resource_object
        end

        def resource_object
          pact
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

        def to_extended_json
          PactBroker::Api::Decorators::ExtendedPactDecorator.new(pact).to_json(user_options: decorator_context(metadata: identifier_from_path[:metadata]))
        end

        def to_html
          PactBroker.configuration.html_pact_renderer.call(
            pact, {
              base_url: ui_base_url,
              badge_url: badge_url_for_latest_pact(pact, ui_base_url)
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

        def set_post_deletion_response
          latest_pact = pact_service.find_latest_pact(pact_params)
          response_body = { "_links" => { index: { href: base_url } } }
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
            webhook_execution_configuration: webhook_execution_configuration
          }
        end
      end
    end
  end
end
