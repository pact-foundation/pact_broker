require 'pact_broker/api/resources/error_handler'

module PactBroker
  module Api
    module Resources
      describe ErrorHandler do
        describe "call" do

          before do
            allow(ErrorHandler).to receive(:logger).and_return(logger)
            allow(SecureRandom).to receive(:urlsafe_base64).and_return("bYWfn-+yWPlf")
          end

          let(:logger) { double('logger').as_null_object }
          let(:error) { StandardError.new('test error') }
          let(:thing) { double('thing', call: nil, another_call: nil) }
          let(:options) { { env: env, error_reference: "bYWfnyWPlf" } }
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

          it "includes an error reference" do
            expect(response).to receive(:body=) do | body |
              expect(JSON.parse(body)['error']).to include 'reference' => "bYWfnyWPlf"
            end
            subject
          end

          context "when show_backtrace_in_error_response? is true" do
            before do
              allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(true)
            end

            context "when the error is a PactBroker::Error or subclass" do
              let(:error) { Class.new(PactBroker::Error).new('test error') }

              it "does not invoke the api error reporters" do
                expect(thing).to_not receive(:call).with(error, options)
                subject
              end

              it "uses the error message as the message" do
                expect(response).to receive(:body=) do | body |
                  expect(JSON.parse(body)['error']).to include 'message' => "test error"
                end
                subject
              end

              it "includes the backtrace in the error response" do
                expect(response).to receive(:body=) do | body |
                  expect(body).to include("backtrace")
                end
                subject
              end
            end
            context "when the error is not a PactBroker::Error or subclass" do
              it "invokes the api error reporters" do
                expect(thing).to receive(:call).with(error, options)
                subject
              end

              it "uses the error message as the message" do
                expect(response).to receive(:body=) do | body |
                  expect(JSON.parse(body)['error']).to include 'message' => "test error"
                end
                subject
              end

              it "includes the backtrace in the error response" do
                expect(response).to receive(:body=) do | body |
                  expect(body).to include("backtrace")
                end
                subject
              end
            end
          end

          context "when show_backtrace_in_error_response? is false" do
            before do
              allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(false)
            end

            context "when the error is a PactBroker::Error or subclass" do
              let(:error) { Class.new(PactBroker::Error).new('test error') }

              it "does not invoke the api error reporters" do
                expect(thing).to_not receive(:call).with(error, options)
                subject
              end

              it "uses the error message as the message" do
                expect(response).to receive(:body=) do | body |
                  expect(JSON.parse(body)['error']).to include 'message' => "test error"
                end
                subject
              end

              it "does not include the backtrace in the error response" do
                expect(response).to receive(:body=) do | body |
                  expect(body).to_not include("backtrace")
                end
                subject
              end
            end
            context "when the error is not a PactBroker::Error or subclass" do
              it "invokes the api error reporters" do
                expect(thing).to receive(:call).with(error, options)
                subject
              end

              it "uses a hardcoded error message" do
                expect(response).to receive(:body=) do | body |
                  expect(JSON.parse(body)['error']['message']).to match /An error/
                end
                subject
              end

              it "does not include the backtrace in the error response" do
                expect(response).to receive(:body=) do | body |
                  expect(body).to_not include("backtrace")
                end
                subject
              end
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
  end
end
