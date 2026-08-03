require "pact_broker/services"
require "pact_broker/events/event"
require "pact_broker/logging"
require "pact_broker/events/publisher"
require "pact_broker/async/after_reply"

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
        @pending_webhook_events = []
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
        logger.debug("Event detected", event_name: event.name, event_comment: event.comment)
        if event.triggered_webhooks&.any?
          triggered_webhook_descriptions = event.triggered_webhooks.collect{ |tw| { event_name: event.name, webhook_uuid: tw.webhook_uuid, triggered_webhook_uuid: tw.uuid, webhook_description: tw.webhook.description } }
          logger.debug("Triggered webhooks for #{event.name}", triggered_webhooks: triggered_webhook_descriptions)
        else
          logger.debug "No enabled webhooks found for event #{event.name}"
        end
      end

      def schedule_triggered_webhooks
        if after_reply_available?
          # Deferred work is collected as pending lambdas; push them to after_reply now that
          # finish_request has confirmed the response code is < 400.
          pending_webhook_events.each do |work|
            PactBroker::Async::AfterReply.new(
              rack_after_reply: webhook_options[:rack_after_reply],
              database_connector: webhook_options[:database_connector]
            ).execute(&work)
          end
        else
          webhook_trigger_service.schedule_webhooks(detected_events.flat_map(&:triggered_webhooks), webhook_options)
        end
      end

      def webhooks_deferred?
        after_reply_available? && detected_events.any?
      end

      private

      attr_reader :webhook_options, :base_webhook_context, :detected_events, :pending_webhook_events

      def after_reply_available?
        webhook_options[:rack_after_reply].is_a?(Array)
      end

      def handle_event_for_webhook(event_name, params)
        if after_reply_available?
          defer_webhook_creation(event_name, params)
        else
          create_and_record_triggered_webhooks(event_name, params)
        end
      end

      def defer_webhook_creation(event_name, params)
        # Record a placeholder event now so callers (e.g. contracts/service.rb notices) can see
        # that an event was detected, even though triggered_webhooks aren't created yet.
        event = PactBroker::Events::Event.new(event_name, params[:event_comment], [])
        detected_events << event
        broadcast(:triggered_webhooks_created_for_event, event: event)
        log_detected_event

        pact = params.fetch(:pact)
        verification = params[:verification]
        event_context = base_webhook_context.merge(params.fetch(:event_context))
        opts = webhook_options

        # Store work as a pending lambda. It will be pushed to rack.after_reply only if
        # finish_request confirms the response code is < 400 (see schedule_triggered_webhooks).
        pending_webhook_events << lambda do
          triggered_webhooks = webhook_trigger_service.create_triggered_webhooks_for_event(pact, verification, event_name, event_context)
          webhook_trigger_service.schedule_webhooks(triggered_webhooks, opts)
        end
      end

      def create_and_record_triggered_webhooks(event_name, params)
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
