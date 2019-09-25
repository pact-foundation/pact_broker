require 'pact_broker/domain/webhook'

module PactBroker
  module Domain
    describe Webhook do
      let(:uuid) { "uuid" }
      let(:consumer) { Pacticipant.new(name: 'Consumer')}
      let(:provider) { Pacticipant.new(name: 'Provider')}
      let(:request_template) { instance_double(PactBroker::Webhooks::WebhookRequestTemplate, build: webhook_request)}
      let(:webhook_request) { instance_double(PactBroker::Domain::WebhookRequest, execute: http_response, http_request: http_request) }
      let(:webhook_template_parameters) { instance_double(PactBroker::Webhooks::PactAndVerificationParameters, to_hash: webhook_template_parameters_hash) }
      let(:webhook_template_parameters_hash) { { 'foo' => 'bar' } }
      let(:http_request) { double('http request') }
      let(:http_response) { double('http response') }
      let(:webhook_context) { { some: 'things' } }
      let(:logging_options) { { other: 'options' } }
      let(:options) { { webhook_context: webhook_context, logging_options: logging_options } }
      let(:pact) { double('pact') }
      let(:verification) { double('verification') }
      let(:logger) { double('logger').as_null_object }

      before do
        allow(webhook).to receive(:logger).and_return(logger)
        allow(PactBroker::Webhooks::PactAndVerificationParameters).to receive(:new).and_return(webhook_template_parameters)
      end

      subject(:webhook) { Webhook.new(uuid: uuid, request: request_template, consumer: consumer, provider: provider) }

      describe "scope_description" do
        subject { webhook.scope_description }

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
          allow(request_template).to receive(:build).and_return(webhook_request)
          allow(PactBroker::Webhooks::WebhookRequestLogger).to receive(:new).and_return(webhook_request_logger)
        end

        let(:webhook_request_logger) { instance_double(PactBroker::Webhooks::WebhookRequestLogger, log: "logs") }

        let(:execute) { subject.execute pact, verification, options }

        it "creates the template parameters" do
          expect(PactBroker::Webhooks::PactAndVerificationParameters).to receive(:new).with(
            pact, verification, webhook_context
          )
          execute
        end

        it "builds the request" do
          expect(request_template).to receive(:build).with(webhook_template_parameters_hash)
          execute
        end

        it "executes the request" do
          expect(webhook_request).to receive(:execute)
          execute
        end

        it "generates the execution logs" do
          expect(webhook_request_logger).to receive(:log).with(uuid, webhook_request, http_response, nil)
          execute
        end

        it "returns a WebhookExecutionResult" do
          expect(execute.request).to_not be nil
          expect(execute.response).to_not be nil
          expect(execute.logs).to eq "logs"
          expect(execute.error).to be nil
        end

        it "logs before and after" do
          allow(logger).to receive(:info)
          expect(logger).to receive(:info).with(/Executing/)
          execute
        end

        context "when an error is thrown" do
          let(:error_class) { Class.new(StandardError) }

          before do
            allow(webhook_request).to receive(:execute).and_raise(error_class)
          end

          it "generates the execution logs" do
            expect(webhook_request_logger).to receive(:log).with(uuid, webhook_request, nil, instance_of(error_class))
            execute
          end

          it "returns a WebhookExecutionResult with an error" do
            expect(execute.request).to_not be nil
            expect(execute.response).to be nil
            expect(execute.logs).to eq "logs"
            expect(execute.error).to_not be nil
          end
        end
      end
    end
  end
end
