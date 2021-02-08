require 'pact_broker/errors'
require 'pact_broker/configuration'

module PactBroker
  module Errors
    describe ".report" do
      before do
        PactBroker.configuration.add_api_error_reporter do | error, options |
          thing.call(error, options)
        end

        PactBroker.configuration.add_api_error_reporter do | error, options |
          thing.another_call(error, options)
        end
      end

      let(:error) { StandardError.new('test error') }
      let(:thing) { double('thing', call: nil, another_call: nil) }
      let(:request) { double('request', env: env ) }
      let(:error_reference) { "bYWfnyWPlf" }
      let(:expected_options) { { env: env, error_reference: "bYWfnyWPlf" } }
      let(:env) { double('env') }

      subject { PactBroker::Errors.report(error, error_reference, request) }


      it "invokes the api error reporters" do
        expect(thing).to receive(:call).with(error, expected_options)
        expect(thing).to receive(:another_call).with(error, expected_options)
        subject
      end

      context "when the error reporter raises an error itself" do
        class TestError < StandardError; end

        let(:logger) { double('logger').as_null_object }

        before do
          expect(thing).to receive(:call).and_raise(TestError.new)
          allow(PactBroker::Errors).to receive(:logger).and_return(logger)
        end

        it "logs the error" do
          expect(logger).to receive(:error).at_least(1).times
          subject
        end

        it "does not propagate the error" do
          expect(thing).to receive(:another_call)
          subject
        end
      end
    end
  end
end
