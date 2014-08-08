require 'spec_helper'
require 'pact_broker/services/webhook_service'

module PactBroker

  module Services
    describe WebhookService do

      describe ".execute_webhook" do

        let(:pact) { instance_double(PactBroker::Models::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Models::Version.new(number: '1.2.3') }
        let(:consumer) { PactBroker::Models::Pacticipant.new(name: 'Consumer') }
        let(:provider) { PactBroker::Models::Pacticipant.new(name: 'Provider') }
        let(:webhook) { instance_double(PactBroker::Models::Webhook)}

        before do
          allow_any_instance_of(PactBroker::Repositories::WebhookRepository).to receive(:find_by_consumer_and_provider).and_return(webhook)
          allow(WebhookService).to receive(:run_later)
        end

        subject { WebhookService.execute_webhook pact }

        it "finds the webhook" do
          expect_any_instance_of(PactBroker::Repositories::WebhookRepository).to receive(:find_by_consumer_and_provider).with(consumer, provider)
          subject
        end

        context "when a webhook exists" do
          it "executes the webhook" do
            expect(WebhookService).to receive(:run_later).with(webhook)
            subject
          end
        end

        context "when a webhook does not exist" do
          let(:webhook) { nil }
          it "does nothing" do
            expect(WebhookService).to_not receive(:run_later)
            subject
          end

          it "logs that no webhook was found" do
            expect(PactBroker.logger).to receive(:debug).with(/No webhook found/)
            subject
          end
        end
      end
    end
  end
end