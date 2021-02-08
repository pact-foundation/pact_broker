require 'pact_broker/api/resources/error_response_body_generator'

module PactBroker
  module Api
    module Resources
      describe ErrorResponseBodyGenerator do
        describe ".call" do
          before do
            allow(error).to receive(:backtrace).and_return(["backtrace"])
          end
          let(:error) { StandardError.new('test error') }
          let(:error_reference) { "bYWfnyWPlf" }

          subject { JSON.parse(ErrorResponseBodyGenerator.call(error, error_reference)) }

          it "includes an error reference" do
            expect(subject['error']).to  include 'reference' => "bYWfnyWPlf"
          end

          context "when show_backtrace_in_error_response? is true" do
            before do
              allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(true)
            end

            context "when the error is a PactBroker::Error or subclass" do
              let(:error) { Class.new(PactBroker::Error).new('test error') }

              it "uses the error message as the message" do
                expect(subject['error']).to include 'message' => "test error"
              end

              it "includes the backtrace in the error response" do
                expect(subject['error']).to include ('backtrace')
              end
            end
          end

          context "when show_backtrace_in_error_response? is false" do
            before do
              allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(false)
            end

            context "when the error is a PactBroker::Error or subclass" do
              let(:error) { Class.new(PactBroker::Error).new('test error') }

              it "uses the error message as the message" do
                expect(subject['error']).to include 'message' => "test error"
              end

              it "does not include the backtrace in the error response" do
                expect(subject['error']).to_not include ('backtrace')
              end
            end

            context "when the error is not a PactBroker::Error or subclass" do
              it "uses a hardcoded error message" do
                expect(subject['error']['message']).to match /An error/
              end

              it "does not include the backtrace in the error response" do
                expect(subject['error']).to_not include ('backtrace')
              end
            end
          end
        end
      end
    end
  end
end
