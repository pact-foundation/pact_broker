require 'pact_broker/logging'
require 'pact_broker/repositories'
require 'pact_broker/services'
require 'pact_broker/messages'
require 'pact_broker/contracts/contracts_publication_results'
require 'pact_broker/contracts/log_message'
require 'pact_broker/events/subscriber'
require 'pact_broker/api/pact_broker_urls'

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

      def publish(parsed_contracts)
        version, version_logs = create_version(parsed_contracts)
        tags = create_tags(parsed_contracts, version)
        pacts, pact_logs = create_pacts(parsed_contracts)
        logs = version_logs + pact_logs
        results = ContractsPublicationResults.from_hash(
          pacticipant: version.pacticipant,
          version: version,
          tags: tags,
          contracts: pacts,
          logs: logs
        )
      end

      # private

      def create_version(parsed_contracts)
        version_params = {
          build_url: parsed_contracts.build_url,
          branch: parsed_contracts.branch
        }.compact

        existing_version = find_existing_version(parsed_contracts)
        version = create_or_update_version(parsed_contracts, version_params)

        message = log_message_for_version_creation(existing_version, parsed_contracts)

        logs = [message]
        return version, logs
      end

      def find_existing_version(parsed_contracts)
        version_service.find_by_pacticipant_name_and_number(
          pacticipant_name: parsed_contracts.pacticipant_name,
          pacticipant_version_number: parsed_contracts.version_number
        )
      end

      def create_or_update_version(parsed_contracts, version_params)
        version_service.create_or_update(
          parsed_contracts.pacticipant_name,
          parsed_contracts.version_number,
          OpenStruct.new(version_params)
        )
      end

      def create_tags(parsed_contracts, version)
        (parsed_contracts.tags || []).collect do | tag_name |
          tag_repository.create(version: version, name: tag_name)
        end
      end

      def create_pacts(parsed_contracts)
        logs = []
        pacts = parsed_contracts.contracts.select(&:pact?).collect do | contract_to_publish |
          pact_params = create_pact_params(parsed_contracts, contract_to_publish)
          existing_pact = pact_service.find_pact(pact_params)
          listener = TriggeredWebhooksCreatedListener.new
          created_pact = create_or_merge_pact(contract_to_publish.merge?, existing_pact, pact_params, listener)
          logs << log_mesage_for_pact_publication(parsed_contracts, contract_to_publish.merge?, existing_pact, created_pact)
          logs.concat(event_and_webhook_logs(listener, created_pact))
          created_pact
        end
        return pacts, logs
      end

      def create_pact_params(parsed_contracts, contract_to_publish)
        PactBroker::Pacts::PactParams.new(
          consumer_name: parsed_contracts.pacticipant_name,
          provider_name: contract_to_publish.provider_name,
          consumer_version_number: parsed_contracts.version_number,
          json_content: contract_to_publish.decoded_content
        )
      end

      def create_or_merge_pact(merge, existing_pact, pact_params, listener)
        PactBroker::Events.subscribe(listener) do
          if merge && existing_pact
            pact_service.merge_pact(pact_params)
          else
            pact_service.create_or_update_pact(pact_params)
          end
        end
      end

      def log_message_for_version_creation(existing_version, parsed_contracts)
        message_params = parsed_contracts.to_h
        if parsed_contracts.tags&.any?
          message_params[:tags] = parsed_contracts.tags.join(", ")
        end
        message_params[:action] = existing_version ? "Updated" : "Created"
        LogMessage.debug(message(log_message_key_for_version_creation(parsed_contracts), message_params))
      end

      def log_message_key_for_version_creation(parsed_contracts)
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

      def log_mesage_for_pact_publication(parsed_contracts, merge, existing_pact, created_pact)
        log_message_params = {
          consumer_name: parsed_contracts.pacticipant_name,
          consumer_version_number: parsed_contracts.version_number,
          provider_name: created_pact.provider_name
        }
        if merge
          if existing_pact
            LogMessage.info(message("messages.contract.pact_merged", log_message_params))
          else
            LogMessage.info(message("messages.contract.pact_published", log_message_params))
          end
        else
          if existing_pact
            if existing_pact.pact_version_sha != created_pact.pact_version_sha
              LogMessage.warn(message("messages.contract.pact_modified_for_same_version", log_message_params))
            else
              LogMessage.info(message("messages.contract.same_pact_content_published", log_message_params))
            end
          else
            LogMessage.info(message("messages.contract.pact_published", log_message_params))
          end
        end
      end

      def event_and_webhook_logs(listener, pact)
        event_descriptions(listener) + triggered_webhook_logs(listener, pact)
      end

      def event_descriptions(listener)
        event_descriptions = listener.detected_events.collect{ | event | event.name + (event.comment ? " (#{event.comment})" : "") }
        if event_descriptions.any?
          [LogMessage.debug("  Events detected: " + event_descriptions.join(", "))]
        else
          []
        end
      end

      def triggered_webhook_logs(listener, pact)
        triggered_webhooks = listener.detected_events.flat_map(&:triggered_webhooks)
        if triggered_webhooks.any?
          triggered_webhooks.collect do | triggered_webhook |
            base_url = triggered_webhook.event_context[:base_url]
            triggered_webhooks_logs_url = PactBroker::Api::PactBrokerUrls.triggered_webhook_logs_url(triggered_webhook, base_url)
            text_2_params = { webhook_description: triggered_webhook.webhook.description&.inspect || triggered_webhook.webhook_uuid, event_name: triggered_webhook.event_name }
            text_1 = message("messages.webhooks.webhook_triggered_for_event", text_2_params)
            text_2 = message("messages.webhooks.triggered_webhook_see_logs", url: triggered_webhooks_logs_url)
            LogMessage.debug("  #{text_1}\n    #{text_2}")
          end
        else
          if webhook_service.find_for_pact(pact).any?
            [LogMessage.debug("  " + message("messages.webhooks.no_webhooks_enabled_for_event"))]
          else
            [LogMessage.debug("  " + message("messages.webhooks.no_webhooks_configured_for_pact"))]
          end
        end
      end
    end
  end
end
