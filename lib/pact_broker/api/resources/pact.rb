require "cgi"
require "pact_broker/api/resources/base_resource"
require "pact_broker/api/resources/pacticipant_resource_methods"
require "pact_broker/api/decorators/pact_decorator"
require "pact_broker/api/decorators/extended_pact_decorator"
require "pact_broker/messages"
require "pact_broker/pacts/pact_params"
require "pact_broker/api/contracts/put_pact_params_contract"
require "pact_broker/webhooks/execution_configuration"
require "pact_broker/api/resources/webhook_execution_methods"
require "pact_broker/api/resources/pact_resource_methods"
require "pact_broker/api/resources/event_methods"
require "pact_broker/integrations/event_listener"

module PactBroker
  module Api
    module Resources
      class Pact < BaseResource
        include EventMethods
        include PacticipantResourceMethods
        include PactResourceMethods
        include WebhookExecutionMethods
        include PactBroker::Messages

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

        def request_body_required?
          request.put? || request.patch?
        end

        def put_can_create?
          true
        end

        def patch_can_create?
          true
        end

        def is_conflict?
          merge_conflict = request.patch? && resource_exists? && Pacts::Merger.conflict?(pact.json_content, pact_params.json_content)

          potential_duplicate_pacticipants?(pact_params.pacticipant_names) || merge_conflict || disallowed_modification?
        end

        def malformed_request?
          super || ((request.patch? || request.really_put?) && validation_errors_for_schema?(schema, pact_params.to_hash_for_validation))
        end

        def resource_exists?
          !!pact
        end

        def from_json
          response_code = pact ? 200 : 201

          subscribe(PactBroker::Integrations::EventListener.new) do
            handle_webhook_events do
              if request.patch? && resource_exists?
                @pact = pact_service.merge_pact(pact_params.merge(pact_version_sha: pact_version_sha))
              else
                @pact = pact_service.create_or_update_pact(pact_params.merge(pact_version_sha: pact_version_sha))
              end
            end
          end
          response.body = to_json
          response_code
        end

        def to_json
          decorator_class(:pact_decorator).new(pact).to_json(**decorator_options(metadata: identifier_from_path[:metadata]))
        end

        def to_extended_json
          decorator_class(:extended_pact_decorator).new(pact).to_json(**decorator_options(metadata: identifier_from_path[:metadata]))
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

        def policy_name
          :'pacts::pact'
        end

        private

        def pact
          @pact ||= pact_service.find_pact(pact_params)
        end

        def disallowed_modification?
          if request.really_put? && pact_service.disallowed_modification?(pact, pact_version_sha)
            message_params = { consumer_name: pact_params.consumer_name, consumer_version_number: pact_params.consumer_version_number, provider_name: pact_params.provider_name }
            set_json_error_message(message("errors.validation.pact_content_modification_not_allowed", message_params))
            true
          else
            false
          end
        end

        def schema
          api_contract_class(:put_pact_params_contract)
        end

        def pact_version_sha
          @pact_version_sha ||= pact_service.generate_sha(pact_params.json_content)
        end
      end
    end
  end
end
