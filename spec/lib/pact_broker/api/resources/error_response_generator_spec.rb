require "pact_broker/api/resources/error_response_generator"

module PactBroker
  module Api
    module Resources
      describe ErrorResponseGenerator do
        describe ".call" do
          before do
            allow(error).to receive(:backtrace).and_return(["backtrace"])
            allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(false)
          end
          let(:error) { StandardError.new("test error") }
          let(:error_reference) { "bYWfnyWPlf" }

          let(:headers_and_body) { ErrorResponseGenerator.call(error, error_reference, rack_env) }
          let(:rack_env) { { "pactbroker.base_url" => "http://example.org" } }
          let(:headers) { headers_and_body.first }

          subject { JSON.parse(headers_and_body.last) }

          it "returns headers" do
            expect(headers).to eq("Content-Type" => "application/hal+json;charset=utf-8")
          end

          it "includes an error reference" do
            expect(subject["error"]).to include "reference" => "bYWfnyWPlf"
          end

          context "when a custom message is provided" do
            let(:headers_and_body) { ErrorResponseGenerator.call(error, error_reference, rack_env, message: "This is a custom message.") }

            it "uses the custom message" do
              expect(subject["error"]["message"]).to include "This is a custom message."
            end
          end

          context "when the Accept header includes application/problem+json" do
            let(:rack_env) { { "HTTP_ACCEPT" => "application/hal+json, application/problem+json", "pactbroker.base_url" => "http://example.org" } }

            it "returns headers" do
              expect(headers).to eq("Content-Type" => "application/problem+json;charset=utf-8")
            end

            it "returns a problem JSON body" do
              expect(subject).to include(
                "title" => "Server error",
                "type" => "http://example.org/problems/server-error",
                "detail" => "An error has occurred. The details have been logged with the reference bYWfnyWPlf"
              )
            end
          end

          context "when show_backtrace_in_error_response? is true" do
            before do
              allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(true)
            end

            context "when the error is a PactBroker::Error or subclass" do
              let(:error) { Class.new(PactBroker::Error).new("test error") }

              it "uses the error message as the message" do
                expect(subject["error"]).to include "message" => "test error"
              end

              it "includes the backtrace in the error response" do
                expect(subject["error"]).to include("backtrace")
              end
            end
          end

          context "when show_backtrace_in_error_response? is false" do
            before do
              allow(PactBroker.configuration).to receive(:show_backtrace_in_error_response?).and_return(false)
            end

            context "when the error is a PactBroker::Error or subclass" do
              let(:error) { Class.new(PactBroker::Error).new("test error") }

              it "uses the error message as the message" do
                expect(subject["error"]).to include "message" => "test error"
              end

              it "does not include the backtrace in the error response" do
                expect(subject["error"]).to_not include("backtrace")
              end
            end

            context "when the error is not a PactBroker::Error or subclass" do
              it "uses a hardcoded error message" do
                expect(subject["error"]["message"]).to match(/An error/)
              end

              it "does not include the backtrace in the error response" do
                expect(subject["error"]).to_not include("backtrace")
              end
            end
          end
        end
      end
    end
  end
end
