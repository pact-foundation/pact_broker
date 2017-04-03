require 'spec_helper'
require 'pact_broker/webhooks/service'

module PactBroker

  module Webhooks
    describe Service do

      describe ".execute_webhooks" do

        let(:pact) { instance_double(PactBroker::Domain::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Domain::Version.new(number: '1.2.3') }
        let(:consumer) { PactBroker::Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { PactBroker::Domain::Pacticipant.new(name: 'Provider') }
        let(:webhooks) { [instance_double(PactBroker::Domain::Webhook)]}

        before do
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_provider).and_return(webhooks)
          allow(Service).to receive(:run_later)
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
      end
    end
  end
end