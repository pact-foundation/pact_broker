require 'spec_helper'
require 'pact_broker/domain/webhook_request'
require 'webmock/rspec'

module PactBroker
  module Domain
    describe WebhookRequest do
      before do
        allow(PactBroker::Api::PactBrokerUrls).to receive(:pact_url).and_return('http://example.org/pact-url')
        allow(PactBroker.configuration).to receive(:base_url).and_return('http://example.org')
        allow(PactBroker.logger).to receive(:info).and_call_original
        allow(PactBroker.logger).to receive(:debug).and_call_original
        allow(PactBroker.logger).to receive(:warn).and_call_original
        allow(PactBroker::Webhooks::CheckHostBlacklist).to receive(:call).and_return([])
      end

      let(:username) { nil }
      let(:password) { nil }
      let(:url) { 'http://example.org/hook' }
      let(:body) { 'body' }
      let(:logs) { StringIO.new }
      let(:execution_logger) { Logger.new(logs) }
      let(:options) { {failure_log_message: 'oops'}}
      let(:pact) { instance_double('PactBroker::Domain::Pact') }

      subject do
        WebhookRequest.new(
          method: 'post',
          url: url,
          headers: {'Content-Type' => 'text/plain', 'Authorization' => 'foo'},
          username: username,
          password: password,
          body: body)
      end

      let(:logs) { subject.execute(pact, options).logs }

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

      describe "execute" do
        let!(:http_request) do
          stub_request(:post, "http://example.org/hook").
            with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
            to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
        end

        describe "when the String body contains a ${pactbroker.pactUrl} parameter" do
          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => "<xml><url>http://example.org/pact-url</url></xml>").
              to_return(:status => 200)
          end

          let(:body) { "<xml><url>${pactbroker.pactUrl}</url></xml>" }

          it "replaces the token with the live value" do
            subject.execute(pact, options)
            expect(http_request).to have_been_made
          end
        end

        describe "when the JSON body contains a ${pactbroker.pactUrl} parameter" do
          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => '{"url":"http://example.org/pact-url"}').
              to_return(:status => 200)
          end

          let(:body) { { url: '${pactbroker.pactUrl}' } }

          it "replaces the token with the live value" do
            subject.execute(pact, options)
            expect(http_request).to have_been_made
          end
        end

        describe "when the URL contains a ${pactbroker.pactUrl} parameter" do
          let!(:http_request) do
            stub_request(:post, "http://example.org/hook?url=http%3A%2F%2Fexample.org%2Fpact-url").
              to_return(:status => 200)
          end

          let(:url) { 'http://example.org/hook?url=${pactbroker.pactUrl}' }

          it "replaces the token with the live value" do
            subject.execute(pact, options)
            expect(http_request).to have_been_made
          end
        end

        it "checks if the host is blacklisted" do
          expect(PactBroker::Webhooks::CheckHostBlacklist).to receive(:call).with('example.org')
          subject.execute(pact, options)
        end

        context "when the URL is not allowed" do
          before do
            allow(PactBroker::Webhooks::CheckHostBlacklist).to receive(:call).and_return(['foo'])
          end

          it "does not execute the HTTP request" do
            subject.execute(pact, options)
            expect(http_request).to_not have_been_made
          end

          it "logs the error" do
            subject.execute(pact, options)
            expect(logs).to include ("PactBroker::Webhooks::WebhookBlacklistedError - Webhook URL http://example.org/hook is blacklisted")
          end
        end

        it "executes the configured request" do
          subject.execute(pact, options)
          expect(http_request).to have_been_made
        end

        it "logs the request" do
          allow(PactBroker.logger).to receive(:info)
          expect(PactBroker.logger).to receive(:info).with(/POST.*example.*text.*body/)
          subject.execute(pact, options)
        end

        it "logs the response" do
          allow(PactBroker.logger).to receive(:info)
          allow(PactBroker.logger).to receive(:debug)
          expect(PactBroker.logger).to receive(:info).with(/response.*200/)
          expect(PactBroker.logger).to receive(:debug).with(/respbod/)
          subject.execute(pact, options)
        end

        it "does not write the response body to the exeuction log for security purposes" do
          expect(logs).to_not include "An error"
        end

        it "logs a message about why there is no response information" do
          expect(logs).to include "Webhook response has been redacted temporarily for security purposes"
        end

        describe "execution logs" do

          it "logs the request method and path" do
            expect(logs).to include "POST http://example.org/hook"
          end

          it "logs the request headers" do
            expect(logs).to include "Content-Type: text/plain"
          end

          it "redacts potentially sensitive headers" do
            expect(logs).to include "Authorization: [REDACTED]"
          end

          it "logs the request body" do
            expect(logs).to include body
          end

          it "logs the response status" do
            expect(logs).to include "HTTP/1.0 200"
          end

          it "does not log the response headers" do
            expect(logs).to_not include "Content-Type: text/foo, blah"
          end

          it "does not log the response body" do
            expect(logs).to_not include "respbod"
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

            it "logs the username and a starred password" do
              expect(logs).to include "POST http://username:**********@example.org/hook"
            end
          end
        end

        describe "when a username and password are specified" do

          let!(:http_request_with_basic_auth) do
            stub_request(:post, "http://example.org/hook").
              with(
                basic_auth: [username, password],
                :headers => {'Content-Type'=>'text/plain'},
                :body => 'body').
              to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          context "with normal characters" do
            let(:username) { "username" }
            let(:password) { "password" }

            it "uses the credentials" do
              subject.execute(pact, options)
              expect(http_request_with_basic_auth).to have_been_made
            end
          end

          context "with special characters" do
            let(:username) { "user_name@site.com" }
            let(:password) { "p@$$w0rd!" }

            it "uses the credentials" do
              subject.execute(pact, options)
              expect(http_request_with_basic_auth).to have_been_made
            end
          end
        end

        context "when the URL has a https scheme" do
          let(:url) { 'https://example.org/hook' }

          let!(:https_request) do
            # webmock will set the request signature scheme to 'https' _only_ if the use_ssl option is set
            stub_request(:post, "https://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "uses SSL" do
            subject.execute(pact, options)
            expect(https_request).to have_been_made
          end
        end

        context "when the request has a JSONable body" do
          let(:body) { [{"some": "json"}] }

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => body.to_json).
              to_return(:status => 200, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "converts the body to JSON before submitting the request" do
            subject.execute(pact, options)
            expect(http_request).to have_been_made
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
            subject.execute(pact, options)
            expect(http_request).to have_been_made
          end
        end

        context "when the request is successful" do
          it "returns a WebhookExecutionResult with success=true" do
            expect(subject.execute(pact, options).success?).to be true
          end

          it "sets the response on the result" do
            expect(subject.execute(pact, options).response).to be_instance_of(Net::HTTPOK)
          end
        end

        context "when the request is not successful" do

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 500, :body => "An error")
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(subject.execute(pact, options).success?).to be false
          end

          it "sets the response on the result" do
            expect(subject.execute(pact, options).response).to be_instance_of(Net::HTTPInternalServerError)
          end
        end

        context "when the response body contains a non UTF-8 character", pending: "execution logs disabled temporarily for security purposes" do
          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              to_return(:status => 200, :body => "This has some \xC2 invalid chars")
          end

          it "removes the non UTF-8 characters before saving the logs so they don't blow up the database" do
            result = subject.execute(pact, options)
            expect(result.logs).to include "This has some  invalid chars"
          end

          it "logs that it has cleaned the string to the execution logger" do
            logger = double("logger").as_null_object
            allow(Logger).to receive(:new).and_return(logger)
            expect(logger).to receive(:debug).with(/Note that invalid UTF-8 byte sequences were removed/)
            subject.execute(pact, options)
          end
        end

        context "when an error occurs executing the request" do

          class WebhookTestError < StandardError; end

          before do
            allow(subject).to receive(:http_request).and_raise(WebhookTestError.new("blah"))
          end

          it "logs the error" do
            allow(PactBroker.logger).to receive(:error)
            expect(PactBroker.logger).to receive(:error).with(/Error.*WebhookTestError.*blah/)
            subject.execute(pact, options)
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(subject.execute(pact, options).success?).to be false
          end

          it "returns a WebhookExecutionResult with an error" do
            expect(subject.execute(pact, options).error).to be_instance_of WebhookTestError
          end

          it "logs the failure_log_message" do
            expect(logs).to include "oops"
          end
        end
      end
    end
  end
end
