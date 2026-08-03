require "pact_broker/webhooks/event_listener"
require "pact_broker/webhooks/webhook_event"
require "pact_broker/events/event"

module PactBroker
  module Webhooks
    describe EventListener do
      let(:pact) { double("pact") }
      let(:verification) { double("verification") }
      let(:triggered_webhook) { double("triggered_webhook", uuid: "tw-uuid", webhook_uuid: "w-uuid", event_name: "contract_published", webhook: double(description: "My webhook")) }
      let(:triggered_webhooks) { [triggered_webhook] }
      let(:event_context) { { base_url: "http://example.org" } }
      let(:base_webhook_context) { { base_url: "http://example.org" } }
      let(:webhook_execution_configuration) { double("webhook_execution_configuration", webhook_context: base_webhook_context) }
      let(:database_connector) { ->(& b) { b.call } }
      let(:webhook_trigger_service) { double("webhook_trigger_service") }
      let(:verification_service) { double("verification_service") }
      let(:logger) { double("logger").as_null_object }

      let(:params) do
        {
          pact: pact,
          verification: verification,
          event_context: event_context,
          event_comment: "some comment"
        }
      end

      let(:webhook_options) do
        {
          webhook_execution_configuration: webhook_execution_configuration,
          database_connector: database_connector
        }
      end

      subject(:listener) { EventListener.new(webhook_options) }

      before do
        allow(subject).to receive(:webhook_trigger_service).and_return(webhook_trigger_service)
        allow(subject).to receive(:verification_service).and_return(verification_service)
        allow(subject).to receive(:logger).and_return(logger)
        allow(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event).and_return(triggered_webhooks)
        allow(webhook_trigger_service).to receive(:schedule_webhooks)
        allow(verification_service).to receive(:find_latest_from_main_branch_for_pact).and_return(verification)
        allow(verification_service).to receive(:calculate_required_verifications_for_pact).and_return([])
      end

      describe "#contract_published" do
        it "creates triggered webhooks for the contract_published event" do
          expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
            .with(pact, anything, WebhookEvent::CONTRACT_PUBLISHED, anything)
          subject.contract_published(params)
        end

        it "records the event in detected_events" do
          subject.contract_published(params)
          expect(subject.detected_events.map(&:name)).to include(WebhookEvent::CONTRACT_PUBLISHED)
        end

        context "when required verifications exist" do
          before do
            allow(verification_service).to receive(:calculate_required_verifications_for_pact).and_return([double("req_ver")])
          end

          it "also creates triggered webhooks for contract_requiring_verification_published" do
            expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
              .with(pact, anything, WebhookEvent::CONTRACT_REQUIRING_VERIFICATION_PUBLISHED, anything)
            subject.contract_published(params)
          end
        end

        context "when no required verifications exist" do
          it "does not create triggered webhooks for contract_requiring_verification_published" do
            expect(webhook_trigger_service).not_to receive(:create_triggered_webhooks_for_event)
              .with(pact, anything, WebhookEvent::CONTRACT_REQUIRING_VERIFICATION_PUBLISHED, anything)
            subject.contract_published(params)
          end
        end
      end

      describe "#contract_content_changed" do
        it "creates triggered webhooks for the contract_content_changed event" do
          expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
            .with(pact, anything, WebhookEvent::CONTRACT_CONTENT_CHANGED, anything)
          subject.contract_content_changed(params)
        end
      end

      describe "#contract_content_unchanged" do
        it "records an event with no triggered webhooks" do
          subject.contract_content_unchanged(params)
          event = subject.detected_events.last
          expect(event.name).to eq "contract_content_unchanged"
          expect(event.triggered_webhooks).to eq []
        end
      end

      describe "#provider_verification_published" do
        it "creates triggered webhooks for the verification_published event" do
          expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
            .with(pact, anything, WebhookEvent::VERIFICATION_PUBLISHED, anything)
          subject.provider_verification_published(params)
        end
      end

      describe "#provider_verification_succeeded" do
        it "creates triggered webhooks for the verification_succeeded event" do
          expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
            .with(pact, anything, WebhookEvent::VERIFICATION_SUCCEEDED, anything)
          subject.provider_verification_succeeded(params)
        end
      end

      describe "#provider_verification_failed" do
        it "creates triggered webhooks for the verification_failed event" do
          expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
            .with(pact, anything, WebhookEvent::VERIFICATION_FAILED, anything)
          subject.provider_verification_failed(params)
        end
      end

      describe "#log_detected_event" do
        context "when the last event has triggered webhooks" do
          before { subject.contract_content_changed(params) }

          it "logs the triggered webhook descriptions" do
            expect(logger).to receive(:debug).with("Triggered webhooks for #{WebhookEvent::CONTRACT_CONTENT_CHANGED}", anything)
            subject.log_detected_event
          end
        end

        context "when the last event has no triggered webhooks" do
          before do
            allow(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event).and_return([])
            subject.contract_content_changed(params)
          end

          it "logs that no webhooks were found" do
            expect(logger).to receive(:debug).with(/No enabled webhooks found/)
            subject.log_detected_event
          end
        end
      end

      describe "#webhooks_deferred?" do
        context "when rack_after_reply is not available" do
          it { expect(subject.webhooks_deferred?).to be false }
        end

        context "when rack_after_reply is an Array and events have been detected" do
          let(:webhook_options) do
            {
              webhook_execution_configuration: webhook_execution_configuration,
              database_connector: database_connector,
              rack_after_reply: []
            }
          end

          before { subject.contract_content_changed(params) }

          it { expect(subject.webhooks_deferred?).to be true }
        end

        context "when rack_after_reply is an Array but no events detected" do
          let(:webhook_options) do
            {
              webhook_execution_configuration: webhook_execution_configuration,
              database_connector: database_connector,
              rack_after_reply: []
            }
          end

          it { expect(subject.webhooks_deferred?).to be false }
        end
      end

      describe "#schedule_triggered_webhooks" do
        context "when rack_after_reply is not available" do
          it "schedules webhooks directly" do
            subject.contract_content_changed(params)
            expect(webhook_trigger_service).to receive(:schedule_webhooks).with(triggered_webhooks, webhook_options)
            subject.schedule_triggered_webhooks
          end
        end

        context "when rack_after_reply is an Array" do
          let(:rack_after_reply) { [] }
          let(:webhook_options) do
            {
              webhook_execution_configuration: webhook_execution_configuration,
              database_connector: database_connector,
              rack_after_reply: rack_after_reply
            }
          end

          before { subject.contract_content_changed(params) }

          it "pushes deferred work to rack_after_reply" do
            subject.schedule_triggered_webhooks
            expect(rack_after_reply.length).to eq 1
          end

          it "executes the webhook creation when the deferred lambda runs" do
            subject.schedule_triggered_webhooks
            expect(webhook_trigger_service).to receive(:create_triggered_webhooks_for_event)
            expect(webhook_trigger_service).to receive(:schedule_webhooks)
            rack_after_reply.first.call
          end
        end
      end
    end
  end
end
