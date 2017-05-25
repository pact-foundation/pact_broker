require 'spec_helper'
require 'pact_broker/webhooks/service'
require 'webmock/rspec'
require 'sucker_punch/testing/inline'

module PactBroker

  module Webhooks
    describe Service do

      describe ".execute_webhooks" do

        let(:pact) { instance_double(PactBroker::Domain::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Domain::Version.new(number: '1.2.3') }
        let(:consumer) { PactBroker::Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { PactBroker::Domain::Pacticipant.new(name: 'Provider') }
        let(:webhooks) { [instance_double(PactBroker::Domain::Webhook, description: 'description', uuid: '1244')]}

        before do
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_provider).and_return(webhooks)
          allow(Job).to receive(:perform_async)
        end

        subject { Service.execute_webhooks pact }

        it "finds the webhooks" do
          expect_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_provider).with(consumer, provider)
          subject
        end

        context "when webhooks are found" do
          it "executes the webhook" do
            expect(Service).to receive(:run_later).with(webhooks)
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

      describe ".execute_webhooks integration test" do
        let!(:http_request) do
          stub_request(:get, "http://example.org").
            to_return(:status => 200)
        end

        let(:pact) do
          ProviderStateBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_webhook(method: 'GET', url: 'http://example.org')
            .and_return(:pact)
        end

        subject { PactBroker::Webhooks::Service.execute_webhooks pact }

        it "executes the HTTP request of the webhook" do
          subject
          expect(http_request).to have_been_made
        end

        it "saves the execution" do
          expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
        end
      end
    end
  end
end
