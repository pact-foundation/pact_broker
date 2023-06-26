require "pact_broker/errors/error_reporter"
require "pact_broker/configuration"

module PactBroker
  module Errors
    describe ErrorReporter do
      before do
        PactBroker.configuration.add_api_error_reporter do | error, options |
          thing.call(error, options)
        end

        PactBroker.configuration.add_api_error_reporter do | error, options |
          thing.another_call(error, options)
        end
      end

      let(:error) { StandardError.new("test error") }
      let(:thing) { double("thing", call: nil, another_call: nil) }
      let(:error_reference) { "bYWfnyWPlf" }
      let(:expected_options) { { env: env, error_reference: "bYWfnyWPlf" } }
      let(:env) { double("env") }
      let(:reporter) { ErrorReporter.new(PactBroker.configuration.api_error_reporters) }

      subject { reporter.call(error, error_reference, env) }


      it "invokes the api error reporters" do
        expect(thing).to receive(:call).with(error, expected_options)
        expect(thing).to receive(:another_call).with(error, expected_options)
        subject
      end

      context "when the error reporter raises an error itself" do
        class TestError < StandardError; end

        before do
          expect(thing).to receive(:call).and_raise(TestError.new)
          allow(reporter).to receive(:logger).and_return(logger)
        end

        let(:logger) { double("logger").as_null_object }

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
