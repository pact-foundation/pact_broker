require "pact_broker/services"
require "pact_broker/events/event"
require "pact_broker/logging"
require "pact_broker/events/publisher"

module PactBroker
  module Webhooks
    class EventListener
      include PactBroker::Services
      include PactBroker::Logging
      include PactBroker::Events::Publisher

      def initialize(webhook_options)
        @webhook_options = webhook_options
        # this has the base URL
        @base_webhook_context = webhook_options[:webhook_execution_configuration].webhook_context
        @detected_events = []
      end

      def contract_published(params)
        main_branch_verification = verification_service.find_latest_from_main_branch_for_pact(params.fetch(:pact))
        handle_event_for_webhook(PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, { verification: main_branch_verification }.compact.merge(params))
        if verification_service.calculate_required_verifications_for_pact(params.fetch(:pact)).any?
          handle_event_for_webhook(PactBroker::Webhooks::WebhookEvent::CONTRACT_REQUIRING_VERIFICATION_PUBLISHED, params)
        end
      end

      def contract_content_changed(params)
        main_branch_verification = verification_service.find_latest_from_main_branch_for_pact(params.fetch(:pact))
        handle_event_for_webhook(PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, { verification: main_branch_verification }.compact.merge(params))
      end

      def contract_content_unchanged(params)
        detected_events << PactBroker::Events::Event.new(
          "contract_content_unchanged",
          params[:event_comment],
          []
        )
        log_detected_event
      end

      def provider_verification_published(params)
        handle_event_for_webhook(PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, params)
      end

      def provider_verification_succeeded(params)
        handle_event_for_webhook(PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, params)
      end

      def provider_verification_failed(params)
        handle_event_for_webhook(PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED, params)
      end

      def log_detected_event
        event = detected_events.last
        logger.debug "Event detected", payload: { event_name: event.name, event_comment: event.comment }
        if event.triggered_webhooks&.any?
          triggered_webhook_descriptions = event.triggered_webhooks.collect{ |tw| { event_name: event.name, webhook_uuid: tw.webhook_uuid, triggered_webhook_uuid: tw.uuid, webhook_description: tw.webhook.description } }
          logger.info "Triggered webhooks for #{event.name}", payload: { triggered_webhooks: triggered_webhook_descriptions }
        else
          logger.debug "No enabled webhooks found for event #{event.name}"
        end
      end

      def schedule_triggered_webhooks
        webhook_trigger_service.schedule_webhooks(detected_events.flat_map(&:triggered_webhooks), webhook_options)
      end

      private

      attr_reader :webhook_options, :base_webhook_context, :detected_events

      def handle_event_for_webhook(event_name, params)
        triggered_webhooks = webhook_trigger_service.create_triggered_webhooks_for_event(
          params.fetch(:pact),
          params[:verification],
          event_name,
          base_webhook_context.merge(params.fetch(:event_context))
        )
        event = PactBroker::Events::Event.new(
          event_name,
          params[:event_comment],
          triggered_webhooks
        )
        detected_events << event
        broadcast(:triggered_webhooks_created_for_event, event: event)
        log_detected_event
      end
    end
  end
end
