require 'spec_helper'
require 'pact_broker/webhooks/service'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/webhook_event'
require 'webmock/rspec'
require 'sucker_punch/testing/inline'

module PactBroker

  module Webhooks
    describe Service do
      let(:td) { TestDataBuilder.new }

      describe ".delete_by_uuid" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook
            .create_deprecated_webhook_execution
        end

        subject { Service.delete_by_uuid td.webhook.uuid }

        it "deletes the webhook" do
          expect { subject }.to change {
            Webhook.count
          }.by(-1)
        end
      end

      describe ".execute_webhooks" do

        let(:pact) { instance_double(PactBroker::Domain::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Domain::Version.new(number: '1.2.3') }
        let(:consumer) { PactBroker::Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { PactBroker::Domain::Pacticipant.new(name: 'Provider') }
        let(:webhooks) { [instance_double(PactBroker::Domain::Webhook, description: 'description', uuid: '1244')]}
        let(:triggered_webhook) { instance_double(PactBroker::Webhooks::TriggeredWebhook) }

        before do
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_provider_and_event_name).and_return(webhooks)
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:create_triggered_webhook).and_return(triggered_webhook)
          allow(Job).to receive(:perform_async)
        end

        subject { Service.execute_webhooks pact, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED }

        it "finds the webhooks" do
          expect_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_provider_and_event_name).with(consumer, provider, PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME)
          subject
        end

        context "when webhooks are found" do
          it "executes the webhook" do
            expect(Service).to receive(:run_later).with(webhooks, pact, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED)
            subject
          end
        end

        context "when no webhooks are found" do
          let(:webhooks) { [] }
          it "does nothing" do
            expect(Service).to_not receive(:run_later)
            subject
          end

          it "logs that no webhook was found" do
            expect(PactBroker.logger).to receive(:debug).with(/No webhook found/)
            subject
          end
        end

        context "when there is a scheduling error" do
          before do
            allow(Job).to receive(:perform_async).and_raise("an error")
          end

          it "logs the error" do
            allow(Service.logger).to receive(:error)
            expect(Service.logger).to receive(:error).with(/an error/)
            subject
          end
        end
      end

      describe ".execute_webhook_now integration test" do
        let(:td) { TestDataBuilder.new }

        let!(:http_request) do
          stub_request(:get, "http://example.org").
            to_return(:status => 200)
        end

        let!(:pact) do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_webhook(method: 'GET', url: 'http://example.org')
            .and_return(:pact)
        end

        subject { PactBroker::Webhooks::Service.execute_webhook_now td.webhook, pact }

        it "executes the HTTP request of the webhook" do
          subject
          expect(http_request).to have_been_made
        end

        it "saves the triggered webhook" do
          expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(1)
        end

        it "saves the execution" do
          expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
        end

        it "marks the triggered webhook as a success" do
          subject
          expect(TriggeredWebhook.first.status).to eq TriggeredWebhook::STATUS_SUCCESS
        end
      end

      describe ".execute_webhooks integration test" do
        let!(:http_request) do
          stub_request(:get, "http://example.org").
            to_return(:status => 200)
        end

        let(:events) { [{ name: PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME }] }

        let(:pact) do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_webhook(method: 'GET', url: 'http://example.org', events: events)
            .and_return(:pact)
        end

        subject { PactBroker::Webhooks::Service.execute_webhooks pact, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED }

        it "executes the HTTP request of the webhook" do
          subject
          expect(http_request).to have_been_made
        end

        it "saves the triggered webhook" do
          expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(1)
        end

        it "saves the execution" do
          expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
        end

        it "marks the triggered webhook as a success" do
          subject
          expect(TriggeredWebhook.first.status).to eq TriggeredWebhook::STATUS_SUCCESS
        end
      end
    end
  end
end
