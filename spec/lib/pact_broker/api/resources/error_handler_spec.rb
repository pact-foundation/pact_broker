require 'pact_broker/api/resources/error_handler'

module PactBroker
  module Api
    module Resources
      describe ErrorHandler do
        describe "call" do
          let(:error) { StandardError.new('test error') }
          let(:thing) { double('thing', call: nil, another_call: nil) }
          let(:options) { { env: env } }
          let(:request) { double('request' ) }
          let(:response) { double('response', :body= => nil) }
          let(:env) { double('env') }

          subject { ErrorHandler.call(error, request, response) }

          before do
            allow(Webmachine::ConvertRequestToRackEnv).to receive(:call).and_return(env)
            PactBroker.configuration.add_api_error_reporter do | error, options |
              thing.call(error, options)
            end

            PactBroker.configuration.add_api_error_reporter do | error, options |
              thing.another_call(error, options)
            end
          end

          it "invokes the api error reporters" do
            expect(thing).to receive(:call).with(error, options)
            expect(thing).to receive(:another_call).with(error, options)
            subject
          end

          context "when the error is a PactBroker::Error or subclass" do
            let(:error) { Class.new(PactBroker::Error).new('test error') }

            it "does not invoke the api error reporters" do
              expect(thing).to_not receive(:call).with(error, options)
              subject
            end
          end

          context "when the error is a PactBroker::TestError" do
            let(:error) { PactBroker::TestError.new('test error') }

            it "invokes the api error reporters" do
              expect(thing).to receive(:call).with(error, options)
              subject
            end
          end

          context "when the error reporter raises an error itself" do
            class TestError < StandardError; end

            before do
              expect(thing).to receive(:call).and_raise(TestError.new)
            end

            it "logs the error" do
              expect(PactBroker.logger).to receive(:error).at_least(1).times
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
  end
end
