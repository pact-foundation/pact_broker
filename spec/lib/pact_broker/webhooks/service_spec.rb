require 'spec_helper'
require 'pact_broker/webhooks/service'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/webhook_event'
require 'webmock/rspec'
require 'sucker_punch/testing/inline'

module PactBroker

  module Webhooks
    describe Service do
      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      let(:td) { TestDataBuilder.new }
      let(:logger) { double('logger').as_null_object }

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

      describe ".trigger_webhooks" do

        let(:verification) { instance_double(PactBroker::Domain::Verification)}
        let(:pact) { instance_double(PactBroker::Domain::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Domain::Version.new(number: '1.2.3') }
        let(:consumer) { PactBroker::Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { PactBroker::Domain::Pacticipant.new(name: 'Provider') }
        let(:webhooks) { [instance_double(PactBroker::Domain::Webhook, description: 'description', uuid: '1244')]}
        let(:triggered_webhook) { instance_double(PactBroker::Webhooks::TriggeredWebhook) }

        before do
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_or_provider_and_event_name).and_return(webhooks)
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:create_triggered_webhook).and_return(triggered_webhook)
          allow(Job).to receive(:perform_in)
        end

        subject { Service.trigger_webhooks pact, verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED }

        it "finds the webhooks" do
          expect_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_or_provider_and_event_name).with(consumer, provider, PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME)
          subject
        end

        context "when webhooks are found" do
          it "executes the webhook" do
            expect(Service).to receive(:run_later).with(webhooks, pact, verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED)
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
            expect(logger).to receive(:debug).with(/No webhook found/)
            subject
          end
        end

        context "when there is a scheduling error" do
          before do
            allow(Job).to receive(:perform_in).and_raise("an error")
          end

          it "logs the error" do
            allow(Service.logger).to receive(:error)
            expect(Service.logger).to receive(:error).with(/an error/)
            subject
          end
        end
      end

      describe ".test_execution" do
        let(:webhook) do
          instance_double(PactBroker::Domain::Webhook,
            trigger_on_provider_verification_published?: trigger_on_verification,
            consumer_name: 'consumer',
            provider_name: 'provider',
            execute: result
          )
        end
        let(:pact) { instance_double(PactBroker::Domain::Pact) }
        let(:verification) { instance_double(PactBroker::Domain::Verification) }
        let(:trigger_on_verification) { false }
        let(:result) { double('result') }
        let(:options) do
          {
            failure_log_message: "Webhook execution failed",
            show_response: 'foo'
          }
        end

        before do
          allow(PactBroker::Pacts::Service).to receive(:search_for_latest_pact).and_return(pact)
          allow(PactBroker::Verifications::Service).to receive(:search_for_latest).and_return(verification)
          allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return('foo')
        end

        subject { Service.test_execution(webhook) }

        it "searches for the latest matching pact" do
          expect(PactBroker::Pacts::Service).to receive(:search_for_latest_pact).with(consumer_name: 'consumer', provider_name: 'provider')
          subject
        end

        it "returns the result" do
          expect(subject).to be result
        end

        context "when the trigger is not for a verification" do
          it "executes the webhook with the pact" do
            expect(webhook).to receive(:execute).with(pact, nil, options)
            subject
          end
        end

        context "when a pact cannot be found" do
          let(:pact) { nil }

          it "executes the webhook with a placeholder pact" do
            expect(webhook).to receive(:execute).with(an_instance_of(PactBroker::Pacts::PlaceholderPact), anything, anything)
            subject
          end
        end

        context "when the trigger is for a verification publication" do
          let(:trigger_on_verification) { true }

          it "searches for the latest matching verification" do
            expect(PactBroker::Verifications::Service).to receive(:search_for_latest).with('consumer', 'provider')
            subject
          end

          it "executes the webhook with the pact and the verification" do
            expect(webhook).to receive(:execute).with(pact, verification, options)
            subject
          end

          context "when a verification cannot be found" do
            let(:verification) { nil }

            it "executes the webhook with a placeholder verification" do
              expect(webhook).to receive(:execute).with(anything, an_instance_of(PactBroker::Verifications::PlaceholderVerification), anything)
              subject
            end
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
            .create_verification
            .and_return(:pact)
        end

        subject { PactBroker::Webhooks::Service.execute_webhook_now td.webhook, pact, td.verification }

        it "executes the HTTP request of the webhook" do
          subject
          expect(http_request).to have_been_made
        end

        it "saves the triggered webhook" do
          expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(1)
        end

        it "saves the pact" do
          subject
          expect(PactBroker::Webhooks::TriggeredWebhook.order(:id).last.pact_publication_id).to_not be nil
        end

        it "saves the verification" do
          subject
          expect(PactBroker::Webhooks::TriggeredWebhook.order(:id).last.verification_id).to_not be nil
        end

        it "saves the execution" do
          expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
        end

        it "marks the triggered webhook as a success" do
          subject
          expect(TriggeredWebhook.first.status).to eq TriggeredWebhook::STATUS_SUCCESS
        end
      end

      describe ".trigger_webhooks integration test" do
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
            .create_verification
            .create_webhook(method: 'GET', url: 'http://example.org', events: events)
            .and_return(:pact)
        end

        subject { PactBroker::Webhooks::Service.trigger_webhooks pact, td.verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED }

        it "executes the HTTP request of the webhook" do
          subject
          expect(http_request).to have_been_made
        end

        it "executes the webhook with the correct options" do
          allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return('foo')
          expected_options = {:show_response => 'foo' }
          expect_any_instance_of(PactBroker::Domain::WebhookRequest).to receive(:execute).with(hash_including(expected_options)).and_call_original
          subject
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
