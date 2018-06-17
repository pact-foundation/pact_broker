require 'pact_broker/domain/webhook'

module PactBroker
  module Domain
    describe Webhook do
      let(:consumer) { Pacticipant.new(name: 'Consumer')}
      let(:provider) { Pacticipant.new(name: 'Provider')}
      let(:request) { instance_double(PactBroker::Domain::WebhookRequest, execute: nil)}
      let(:options) { double('options') }
      let(:pact) { double('pact') }
      let(:verification) { double('verification') }

      subject(:webhook) { Webhook.new(request: request, consumer: consumer, provider: provider) }

      describe "description" do
        subject { webhook.description }

        context "with a consumer and provider" do
          it { is_expected.to eq "A webhook for the pact between Consumer and Provider" }
        end

        context "with a consumer only" do
          let(:provider) { nil }

          it { is_expected.to eq "A webhook for all pacts with consumer Consumer" }
        end

        context "with a provider only" do
          let(:consumer) { nil }

          it { is_expected.to eq "A webhook for all pacts with provider Provider" }
        end

        context "with neither a consumer nor a provider" do
          let(:consumer) { nil }
          let(:provider) { nil }

          it { is_expected.to eq "A webhook for all pacts" }
        end
      end

      describe "execute" do
        it "executes the request" do
          expect(request).to receive(:execute).with(pact, verification, options)
          subject.execute pact, verification, options
        end

        it "logs before and after" do
          allow(PactBroker.logger).to receive(:info)
          expect(PactBroker.logger).to receive(:info).with(/Executing/)
          subject.execute pact, verification, options
        end
      end
    end
  end
end
