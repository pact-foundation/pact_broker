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
        # Buffered event params — populated during the DB transaction, processed after it commits.
        @pending_webhook_events = []
      end

      def contract_published(params)
        main_branch_verification = verification_service.find_latest_from_main_branch_for_pact(params.fetch(:pact))
        buffer_event_for_webhook(PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, { verification: main_branch_verification }.compact.merge(params))
        if verification_service.calculate_required_verifications_for_pact(params.fetch(:pact)).any?
          buffer_event_for_webhook(PactBroker::Webhooks::WebhookEvent::CONTRACT_REQUIRING_VERIFICATION_PUBLISHED, params)
        end
      end

      def contract_content_changed(params)
        main_branch_verification = verification_service.find_latest_from_main_branch_for_pact(params.fetch(:pact))
        buffer_event_for_webhook(PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, { verification: main_branch_verification }.compact.merge(params))
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
        buffer_event_for_webhook(PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, params)
      end

      def provider_verification_succeeded(params)
        buffer_event_for_webhook(PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, params)
      end

      def provider_verification_failed(params)
        buffer_event_for_webhook(PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED, params)
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

      # Called by WebhookExecutionMethods#finish_request only when response.code < 400.
      # Registers the rack.after_reply callback so that TriggeredWebhook creation and job
      # scheduling happen after the transaction commits, not inside it (PACT-7218).
      def schedule_triggered_webhooks
        register_after_reply_callback if @pending_webhook_events.any?
      end

      private

      attr_reader :webhook_options, :base_webhook_context, :detected_events

      # Buffers the event params during the transaction. No DB writes occur here.
      # The rack.after_reply callback is registered later by schedule_triggered_webhooks,
      # which is only called when response.code < 400 (PACT-7218).
      def buffer_event_for_webhook(event_name, params)
        @pending_webhook_events << { event_name: event_name, params: params }
        # Emit a placeholder event so callers (e.g. the publish_contracts response notices) can
        # see that events were detected, even though triggered_webhooks won't be populated yet.
        event = PactBroker::Events::Event.new(event_name, params[:event_comment], [])
        detected_events << event
        broadcast(:triggered_webhooks_created_for_event, event: event)
        log_detected_event
      end

      def register_after_reply_callback
        rack_env = webhook_options[:rack_env]
        database_connector = webhook_options[:database_connector]
        pending = @pending_webhook_events

        rack_env["rack.after_reply"] << lambda {
          begin
            if database_connector
              database_connector.call { create_and_schedule_triggered_webhooks(pending) }
            else
              create_and_schedule_triggered_webhooks(pending)
            end
          rescue StandardError => e
            logger.error("Error creating/scheduling triggered webhooks after reply", e)
          end
        }
      end
      private :register_after_reply_callback

      # Runs after the transaction commits via rack.after_reply.
      def create_and_schedule_triggered_webhooks(pending_webhook_events)
        all_triggered_webhooks = pending_webhook_events.flat_map do |buffered|
          event_name = buffered[:event_name]
          params     = buffered[:params]
          webhook_trigger_service.create_triggered_webhooks_for_event(
            params.fetch(:pact),
            params[:verification],
            event_name,
            base_webhook_context.merge(params.fetch(:event_context))
          )
        end
        webhook_trigger_service.schedule_webhooks(all_triggered_webhooks, webhook_options)
      end
    end
  end
end
