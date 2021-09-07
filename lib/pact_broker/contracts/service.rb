require "pact_broker/logging"
require "pact_broker/repositories"
require "pact_broker/services"
require "pact_broker/messages"
require "pact_broker/contracts/contracts_publication_results"
require "pact_broker/contracts/notice"
require "pact_broker/events/subscriber"
require "pact_broker/api/pact_broker_urls"

module PactBroker
  module Contracts
    module Service
      extend self
      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      extend PactBroker::Messages

      class TriggeredWebhooksCreatedListener
        attr_reader :detected_events

        def initialize
          @detected_events = []
        end

        def triggered_webhooks_created_for_event(params)
          detected_events << params.fetch(:event)
        end
      end

      def publish(parsed_contracts, base_url: )
        version, version_notices = create_version(parsed_contracts)
        tags = create_tags(parsed_contracts, version)
        pacts, pact_notices = create_pacts(parsed_contracts, base_url)
        notices = version_notices + pact_notices
        ContractsPublicationResults.from_hash(
          pacticipant: version.pacticipant,
          version: version,
          tags: tags,
          contracts: pacts,
          notices: notices
        )
      end

      def create_version(parsed_contracts)
        version_params = {
          build_url: parsed_contracts.build_url,
          branch: parsed_contracts.branch
        }.compact

        existing_version = find_existing_version(parsed_contracts)
        version = create_or_update_version(parsed_contracts, version_params)
        return version, notices_for_version_creation(existing_version, parsed_contracts)
      end

      private :create_version

      def find_existing_version(parsed_contracts)
        version_service.find_by_pacticipant_name_and_number(
          pacticipant_name: parsed_contracts.pacticipant_name,
          pacticipant_version_number: parsed_contracts.pacticipant_version_number
        )
      end

      private :find_existing_version

      def create_or_update_version(parsed_contracts, version_params)
        version_service.create_or_update(
          parsed_contracts.pacticipant_name,
          parsed_contracts.pacticipant_version_number,
          OpenStruct.new(version_params)
        )
      end

      private :create_or_update_version

      def create_tags(parsed_contracts, version)
        (parsed_contracts.tags || []).collect do | tag_name |
          tag_service.create(pacticipant_name: version.pacticipant.name, pacticipant_version_number: version.number, tag_name: tag_name)
        end
      end

      private :create_tags

      def create_pacts(parsed_contracts, base_url)
        notices = []
        pacts = parsed_contracts.contracts.select(&:pact?).collect do | contract_to_publish |
          pact_params = create_pact_params(parsed_contracts, contract_to_publish)
          existing_pact = pact_service.find_pact(pact_params)
          listener = TriggeredWebhooksCreatedListener.new
          created_pact = create_or_merge_pact(contract_to_publish.merge?, existing_pact, pact_params, listener)
          notices.concat(notices_for_pact(parsed_contracts, contract_to_publish, existing_pact, created_pact, listener, base_url))
          created_pact
        end
        return pacts, notices
      end

      private :create_pacts

      def create_pact_params(parsed_contracts, contract_to_publish)
        PactBroker::Pacts::PactParams.new(
          consumer_name: parsed_contracts.pacticipant_name,
          provider_name: contract_to_publish.provider_name,
          consumer_version_number: parsed_contracts.pacticipant_version_number,
          json_content: contract_to_publish.decoded_content
        )
      end

      private :create_pact_params

      def create_or_merge_pact(merge, existing_pact, pact_params, listener)
        PactBroker::Events.subscribe(listener) do
          if merge && existing_pact
            pact_service.merge_pact(pact_params)
          else
            pact_service.create_or_update_pact(pact_params)
          end
        end
      end

      private :create_or_merge_pact

      def notices_for_version_creation(existing_version, parsed_contracts)
        notices = []
        message_params = parsed_contracts.to_h
        if parsed_contracts.tags&.any?
          message_params[:tags] = parsed_contracts.tags.join(", ")
        end
        message_params[:action] = existing_version ? "Updated" : "Created"
        notices << Notice.debug(message(message_key_for_version_creation(parsed_contracts), message_params))
        if parsed_contracts.branch.nil?
          notices << Notice.prompt("  Next steps:\n    " + message("messages.next_steps.version_branch"))
        end
        notices
      end

      private :notices_for_version_creation

      def message_key_for_version_creation(parsed_contracts)
        if parsed_contracts.branch && parsed_contracts.tags&.any?
          "messages.version.created_for_branch_with_tags"
        elsif parsed_contracts.branch
          "messages.version.created_for_branch"
        elsif parsed_contracts.tags&.any?
          "messages.version.created_with_tags"
        else
          "messages.version.created"
        end
      end

      private :message_key_for_version_creation

      # rubocop: disable Metrics/ParameterLists
      def notices_for_pact(parsed_contracts, contract_to_publish, existing_pact, created_pact, listener, base_url)
        notices = []
        notices << notice_for_pact_publication(parsed_contracts, contract_to_publish.merge?, existing_pact, created_pact)
        notices << notice_for_pact_url(created_pact, base_url)
        notices.concat(event_and_webhook_notices(listener, created_pact))
        notices.concat(next_steps_notices(created_pact))
        notices
      end
      # rubocop: enable Metrics/ParameterLists

      private :notices_for_pact

      def notice_for_pact_publication(parsed_contracts, merge, existing_pact, created_pact)
        message_params = {
          consumer_name: parsed_contracts.pacticipant_name,
          consumer_version_number: parsed_contracts.pacticipant_version_number,
          provider_name: created_pact.provider_name
        }
        if merge
          if existing_pact
            Notice.success(message("messages.contract.pact_merged", message_params))
          else
            Notice.success(message("messages.contract.pact_published", message_params))
          end
        else
          if existing_pact
            if existing_pact.pact_version_sha != created_pact.pact_version_sha
              Notice.warning(message("messages.contract.pact_modified_for_same_version", message_params))
            else
              Notice.success(message("messages.contract.same_pact_content_published", message_params))
            end
          else
            Notice.success(message("messages.contract.pact_published", message_params))
          end
        end
      end

      private :notice_for_pact_publication

      def notice_for_pact_url(pact, base_url)
        Notice.debug("  View the published pact at #{PactBroker::Api::PactBrokerUrls.pact_url(base_url, pact)}")
      end

      private :notice_for_pact_url

      def event_and_webhook_notices(listener, pact)
        event_descriptions(listener) + triggered_webhook_notices(listener, pact)
      end

      private :event_and_webhook_notices

      def event_descriptions(listener)
        event_descriptions = listener.detected_events.collect{ | event | event.name + (event.comment ? " (#{event.comment})" : "") }
        if event_descriptions.any?
          [Notice.debug("  Events detected: " + event_descriptions.join(", "))]
        else
          []
        end
      end

      private :event_descriptions

      # TODO add can-i-deploy and record-deployment
      def next_steps_notices(pact)
        notices = []
        if !verification_service.any_verifications?(pact.consumer, pact.provider)
          notices << Notice.prompt("    * " + message("messages.next_steps.verifications", provider_name: pact.provider_name))
        end

        if !webhook_service.any_webhooks_configured_for_pact?(pact)
          notices << Notice.prompt("    * " + message("messages.next_steps.webhooks", provider_name: pact.provider_name))
        end

        if notices.any?
          notices.unshift(Notice.prompt("  Next steps:"))
        end

        notices
      end

      private :next_steps_notices

      def triggered_webhook_notices(listener, pact)
        triggered_webhooks = listener.detected_events.flat_map(&:triggered_webhooks)
        if triggered_webhooks.any?
          triggered_webhooks.collect do | triggered_webhook |
            base_url = triggered_webhook.event_context[:base_url]
            triggered_webhooks_notices_url = url_for_triggered_webhook(triggered_webhook, base_url)
            text_2_params = { webhook_description: triggered_webhook.webhook.description&.inspect || triggered_webhook.webhook_uuid, event_name: triggered_webhook.event_name }
            text_1 = message("messages.webhooks.webhook_triggered_for_event", text_2_params)
            text_2 = message("messages.webhooks.triggered_webhook_see_logs", url: triggered_webhooks_notices_url)
            Notice.debug("  #{text_1}\n    #{text_2}")
          end
        else
          if webhook_service.any_webhooks_configured_for_pact?(pact)
            # There are some webhooks, just not any for this particular event
            [Notice.debug("  " + message("messages.webhooks.no_webhooks_enabled_for_event"))]
          else
            []
          end
        end
      end

      def url_for_triggered_webhook(triggered_webhook, base_url)
        PactBroker::Api::PactBrokerUrls.triggered_webhook_logs_url(triggered_webhook, base_url)
      end

      private :url_for_triggered_webhook
    end
  end
end
