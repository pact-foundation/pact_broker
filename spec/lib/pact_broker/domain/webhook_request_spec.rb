require 'spec_helper'
require 'pact_broker/domain/webhook_request'
require 'webmock/rspec'

module PactBroker
  module Domain
    describe WebhookRequest do
      let(:username) { nil }
      let(:password) { nil }
      let(:url) { 'http://example.org/hook' }
      let(:headers) { {'Content-Type' => 'text/plain', 'Authorization' => 'foo'} }
      let(:body) { 'reqbody' }
      let(:logs) { StringIO.new }
      let(:logger) { double('logger').as_null_object }
      let(:execution_logger) { Logger.new(logs) }
      let(:options) { {failure_log_message: 'oops', show_response: show_response} }
      let(:show_response) { true }
      let(:logs) { execute.logs }

      subject do
        WebhookRequest.new(
          method: 'post',
          url: url,
          headers: headers,
          username: username,
          password: password,
          body: body)
      end

      let(:execute) { subject.execute(options) }

      describe "description" do
        it "returns a brief description of the HTTP request" do
          expect(subject.description).to eq 'POST example.org'
        end
      end

      describe "display_password" do
        context "when a password is set" do
          let(:password) { 'password' }
          it "returns stars" do
            expect(subject.display_password).to eq "**********"
          end
        end
        context "when a password is not set" do
          it "returns nil" do
            expect(subject.display_password).to eq nil
          end
        end
      end

      describe "redacted_headers" do
        let(:headers) do
          {
            'Authorization' => 'foo',
            'X-authorization' => 'bar',
            'token' => 'bar',
            'Token' => 'bar',
            'X-Auth-Token' => 'bar',
            'X-Authorization-Token' => 'bar',
            'OK' => 'ok'
          }
        end

        let(:expected_headers) do
          {
            'Authorization' => '**********',
            'X-authorization' => '**********',
            'token' => '**********',
            'Token' => '**********',
            'X-Auth-Token' => '**********',
            'X-Authorization-Token' => '**********',
            'OK' => 'ok'
          }
        end

        it "redacts sensitive headers" do
          expect(subject.redacted_headers).to eq expected_headers
        end
      end

      describe "execute" do
        let!(:http_request) do
          stub_request(:post, "http://example.org/hook").
            with(:headers => {'Content-Type'=>'text/plain'}, :body => request_body).
            to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
        end

        before do
          allow(WebhookRequest).to receive(:logger).and_return(logger)
          allow(WebhookRequest.logger).to receive(:info)
          allow(WebhookRequest.logger).to receive(:debug)
        end

        let(:request_body) { 'reqbody' }

        it "executes the configured request" do
          execute
          expect(http_request).to have_been_made
        end

        it "logs the request" do
          expect(logger).to receive(:info).with(/POST.*example/)
          expect(logger).to receive(:debug).with(/.*text\/plain/)
          expect(logger).to receive(:debug).with(/.*reqbody/)
          execute
        end

        it "logs the response" do
          allow(logger).to receive(:info)
          allow(logger).to receive(:debug)
          expect(logger).to receive(:info).with(/response.*200/)
          expect(logger).to receive(:debug).with(/text\/foo/)
          expect(logger).to receive(:debug).with(/respbod/)
          execute
        end

        describe "execution logs" do

          it "logs the request method and path" do
            expect(logs).to include "POST http://example.org/hook"
          end

          it "logs the request headers" do
            expect(logs).to include "content-type: text/plain"
          end

          it "redacts potentially sensitive headers" do
            expect(logs).to include "authorization: **********"
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
              expect(logs).to include "security purposes"
            end
          end

          context "when the response code is a success" do
            it "does not log the failure_log_message" do
              allow_any_instance_of(WebhookExecutionResult).to receive(:success?).and_return(true)
              expect(logs).to_not include "oops"
            end
          end

          context "when the response code is not successful" do
            it "logs the failure_log_message" do
              allow_any_instance_of(WebhookExecutionResult).to receive(:success?).and_return(false)
              expect(logs).to include "oops"
            end
          end

          context "with basic auth" do
            let(:username) { 'username' }
            let(:password) { 'password' }

            it "logs the Authorization header with a starred value" do
              expect(logs).to include "authorization: **********"
            end
          end
        end

        describe "when a username and password are specified" do

          let!(:http_request_with_basic_auth) do
            stub_request(:post, "http://example.org/hook").
              with(
                basic_auth: [username, password],
                :headers => {'Content-Type'=>'text/plain'},
                :body => 'reqbody').
              to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          context "with normal characters" do
            let(:username) { "username" }
            let(:password) { "password" }

            it "uses the credentials" do
              execute
              expect(http_request_with_basic_auth).to have_been_made
            end
          end

          context "with special characters" do
            let(:username) { "user_name@site.com" }
            let(:password) { "p@$$w0rd!" }

            it "uses the credentials" do
              execute
              expect(http_request_with_basic_auth).to have_been_made
            end
          end
        end

        context "when the URL has a https scheme" do
          let(:url) { 'https://example.org/hook' }

          let!(:https_request) do
            # webmock will set the request signature scheme to 'https' _only_ if the use_ssl option is set
            stub_request(:post, "https://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'reqbody').
              to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "uses SSL" do
            execute
            expect(https_request).to have_been_made
          end
        end

        context "when the request has a nil body" do
          let(:body) { nil }

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => nil).
              to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "executes the request without a body" do
            execute
            expect(http_request).to have_been_made
          end
        end

        context "when the request is successful" do
          it "returns a WebhookExecutionResult with success=true" do
            expect(execute.success?).to be true
          end

          it "sets the response on the result" do
            expect(execute.response).to be_instance_of(WebhookResponseWithUtf8SafeBody)
          end
        end

        context "when the request is not successful" do

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'reqbody').
              to_return(:status => 500, :body => "An error")
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(execute.success?).to be false
          end

          it "sets the response on the result" do
            expect(execute.response).to be_instance_of(WebhookResponseWithUtf8SafeBody)
          end
        end

        context "when the response body contains a non UTF-8 character" do
          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              to_return(:status => 200, :body => "This has some \xC2 invalid chars")
          end

          it "removes the non UTF-8 characters before saving the logs so they don't blow up the database" do
            result = execute
            expect(result.logs).to include "This has some  invalid chars"
          end

          it "logs that it has cleaned the string to the execution logger" do
            logger = double("logger").as_null_object
            allow(Logger).to receive(:new).and_return(logger)
            expect(logger).to receive(:debug).with(/Note that invalid UTF-8 byte sequences were removed/)
            execute
          end
        end

        context "when an error occurs executing the request" do

          class WebhookTestError < StandardError; end

          before do
            allow(Net::HTTP).to receive(:start).and_raise(WebhookTestError.new("blah"))
            allow(logger).to receive(:error)
          end

          it "logs the error" do
            expect(logger).to receive(:info).with(/Error.*WebhookTestError.*blah/)
            execute
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(execute.success?).to be false
          end

          it "returns a WebhookExecutionResult with an error" do
            expect(execute.error).to be_instance_of WebhookTestError
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
              expect(logs).to include "security purposes"
            end
          end
        end
      end
    end
  end
end
