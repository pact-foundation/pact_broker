require 'pact_broker/domain/webhook'

module PactBroker
  module Domain
    describe Webhook do
      let(:consumer) { Pacticipant.new(name: 'Consumer')}
      let(:provider) { Pacticipant.new(name: 'Provider')}
      let(:request_template) { instance_double(PactBroker::Webhooks::WebhookRequestTemplate, build: request)}
      let(:request) { instance_double(PactBroker::Domain::WebhookRequest, execute: result) }
      let(:result) { double('result') }
      let(:webhook_context) { { some: 'things' } }
      let(:options) { { base_url: base_url, context: webhook_context } }
      let(:base_url) { "http://broker" }
      let(:pact) { double('pact') }
      let(:verification) { double('verification') }
      let(:logger) { double('logger').as_null_object }

      before do
        allow(webhook).to receive(:logger).and_return(logger)
      end

      subject(:webhook) { Webhook.new(request: request_template, consumer: consumer, provider: provider) }

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
        before do
          allow(request_template).to receive(:build).and_return(request)
        end

        let(:execute) { subject.execute pact, verification, options }

        it "builds the request" do
          expect(request_template).to receive(:build).with(
            pact: pact,
            verification: verification,
            base_url: base_url,
            webhook_context: webhook_context)
          execute
        end

        it "executes the request" do
          expect(request).to receive(:execute).with(options)
          execute
        end

        it "logs before and after" do
          allow(logger).to receive(:info)
          expect(logger).to receive(:info).with(/Executing/)
          execute
        end
      end
    end
  end
end
