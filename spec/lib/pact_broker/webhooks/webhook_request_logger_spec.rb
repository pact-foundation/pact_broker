require "pact_broker/webhooks/webhook_request_logger"
require "pact_broker/domain/webhook_request"

module PactBroker
  module Webhooks
    describe WebhookRequestLogger do
      before do
        if response
          response_headers.each do | key, value |
            allow(response).to receive(:each_header).and_yield(key, value)
          end
        end
        allow(webhook_request_logger).to receive(:logger).and_return(logger)
        subject
      end

      let(:logger) { double("logger").as_null_object }
      let(:uuid) { "uuid" }
      let(:options) { { failure_log_message: "oops", show_response: show_response, http_code_success: [200], redact_sensitive_data: redact_sensitive_data } }
      let(:redact_sensitive_data) { true }
      let(:show_response) { true }
      let(:username) { nil }
      let(:password) { nil }
      let(:url) { "http://example.org/hook" }
      let(:headers) { {"Content-Type" => "text/plain", "Authorization" => "foo"} }
      let(:body) { "reqbody" }
      let(:webhook_request) do
        PactBroker::Domain::WebhookRequest.new(
          method: "post",
          url: url,
          headers: headers,
          username: username,
          password: password,
          body: body)
      end
      let(:error) { nil }
      let(:status) { 200 }
      let(:response) do
        double("response",
          http_version: "1.0",
          message: "OK",
          code: status,
          body: response_body,
          to_hash: response_headers
        )
      end
      let(:response_body) { "respbod" }
      let(:response_headers) do
        {
          "content-type" => "text/foo, blah"
        }
      end

      let(:base_url) { "http://example.org" }
      let(:webhook_context) { { consumer_version_number: "123", base_url: base_url } }

      let(:webhook_request_logger) { WebhookRequestLogger.new(options) }
      let(:success) { true }

      subject(:logs) { webhook_request_logger.log(uuid, webhook_request, response, success, error, webhook_context) }

      describe "application logs" do
        it "logs the request" do
          expect(logger).to have_received(:info).with(/POST.*example/)
          expect(logger).to have_received(:debug).with(/.*text\/plain/)
          expect(logger).to have_received(:debug).with(/.*reqbody/)
        end

        it "logs the response" do
          expect(logger).to have_received(:info).with(/response.*200/)
          expect(logger).to have_received(:debug).with(/text\/foo/)
          expect(logger).to have_received(:debug).with(/respbod/)
        end
      end

      describe "execution logs" do
        it "logs the application context" do
          expect(logs).to include webhook_context.to_json
        end

        it "logs the request method and path" do
          expect(logs).to include "POST http://example.org/hook"
        end

        it "logs the request headers" do
          expect(logs).to include "content-type: text/plain"
        end

        it "logs the request body" do
          expect(logs).to include body
        end

        context "when show_response is true" do
          it "logs the response status" do
            expect(logs).to include "HTTP/1.0 200"
          end

          it "logs the response headers" do
            expect(logs).to include "content-type: text/foo, blah"
          end

          it "logs the response body" do
            expect(logs).to include "respbod"
          end
        end

        context "when show_response is false" do
          let(:show_response) { false }

          it "does not log the response status" do
            expect(logs).to_not include "HTTP/1.0 200"
          end

          it "does not log the response headers" do
            expect(logs).to_not include "content-type: text/foo, blah"
          end

          it "does not log the response body" do
            expect(logs).to_not include "respbod"
          end

          it "logs a message about why the response is hidden" do
            expect(logs).to include base_url
            expect(logs).to include "security purposes"
          end
        end

        context "when the response code is a success" do
          it "does not log the failure_log_message" do
            expect(logs).to_not include "oops"
          end
        end

        context "when the status is not successful" do
          let(:success) { false }

          it "logs the failure_log_message" do
            expect(logs).to include "oops"
          end
        end

        context "with basic auth" do
          let(:headers) { { "authorization" => "foo" } }

          it "logs the Authorization header with a starred value" do
            expect(logs).to include "authorization: **********"
          end

          context "when redact_sensitive_data is false" do
            let(:redact_sensitive_data) { false }

            it "logs the real value of the Authorization header" do
              expect(logs).to include "authorization: foo"
            end
          end
        end

        context "when the response body contains a non UTF-8 character" do
          let(:response_body) { "This has some \xC2 invalid chars" }

          it "logs the safe body so it doesn't blow up the database" do
            expect(logs).to include "This has some  invalid chars"
          end

          it "logs that it has cleaned the string to the execution logger" do
            expect(logs).to include("Note that invalid UTF-8 byte sequences were removed")
          end
        end

        context "when an error occurs executing the request" do

          class WebhookTestError < StandardError; end

          before do
            allow(error).to receive(:backtrace).and_return([])
          end

          let(:response) { nil }
          let(:success) { false }
          let(:error) do
            err = WebhookTestError.new("blah")
            allow(err).to receive(:backtrace).and_return([])
            err
          end

          it "logs the error" do
            expect(logger).to have_received(:info).with(/Error.*WebhookTestError.*blah/)
          end

          it "logs the failure_log_message" do
            expect(logs).to include "oops"
          end

          context "when show_response is true" do
            it "logs the exception information" do
              expect(logs).to include "blah"
            end
          end

          context "when show_response is false" do
            let(:show_response) { false }

            it "does not logs the exception information" do
              expect(logs).to_not include "blah"
            end

            it "logs a message about why the response is hidden" do
              expect(logs).to include base_url
              expect(logs).to include "security purposes"
            end
          end
        end
      end
    end
  end
end
