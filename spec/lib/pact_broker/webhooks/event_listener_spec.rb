require "pact_broker/webhooks/event_listener"

module PactBroker
  module Webhooks
    describe EventListener do
      let(:rack_env) { { "rack.after_reply" => after_reply_callbacks } }
      let(:after_reply_callbacks) { [] }
      let(:database_connector) { ->(& block) { block.call } }
      let(:webhook_execution_configuration) { double("webhook_execution_configuration", webhook_context: {}) }
      let(:webhook_options) do
        {
          database_connector: database_connector,
          rack_env: rack_env,
          webhook_execution_configuration: webhook_execution_configuration
        }
      end
      let(:event_listener) { EventListener.new(webhook_options) }
      let(:pact) { double("pact") }
      let(:triggered_webhooks) { [double("triggered_webhook", uuid: "tw-uuid", webhook_uuid: "w-uuid", webhook: double("webhook", description: "test webhook"))] }
      let(:webhook_trigger_service) { class_double("PactBroker::Webhooks::TriggerService").as_stubbed_const }

      before do
        allow(event_listener).to receive(:verification_service).and_return(double("verification_service",
          find_latest_from_main_branch_for_pact: nil,
          calculate_required_verifications_for_pact: []
        ))
        allow(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event).and_return(triggered_webhooks)
        allow(webhook_trigger_service).to receive(:schedule_webhooks)
      end

      describe "#contract_published" do
        let(:params) { { pact: pact, event_context: { some: "context" } } }

        subject { event_listener.contract_published(params) }

        it "does not create triggered webhooks during the request" do
          subject
          expect(webhook_trigger_service).not_to have_received(:create_triggered_webhooks_for_event)
        end

        it "does not enqueue a rack.after_reply callback before schedule_triggered_webhooks is called" do
          event_listener.contract_published(params)
          expect(after_reply_callbacks.size).to eq 0
        end
      end

      describe "#schedule_triggered_webhooks" do
        let(:params) { { pact: pact, event_context: { some: "context" } } }

        it "enqueues a single rack.after_reply callback for all buffered events" do
          event_listener.contract_published(params)
          event_listener.contract_published(params)
          event_listener.schedule_triggered_webhooks
          expect(after_reply_callbacks.size).to eq 1
        end

        it "does not enqueue a callback when there are no pending events" do
          event_listener.schedule_triggered_webhooks
          expect(after_reply_callbacks.size).to eq 0
        end

        it "creates triggered webhooks after the reply" do
          event_listener.contract_published(params)
          event_listener.schedule_triggered_webhooks
          after_reply_callbacks.each(&:call)
          expect(webhook_trigger_service).to have_received(:create_triggered_webhooks_for_event)
        end

        it "schedules the triggered webhooks after the reply" do
          event_listener.contract_published(params)
          event_listener.schedule_triggered_webhooks
          after_reply_callbacks.each(&:call)
          expect(webhook_trigger_service).to have_received(:schedule_webhooks).with(triggered_webhooks, webhook_options)
        end
      end
    end
  end
end
