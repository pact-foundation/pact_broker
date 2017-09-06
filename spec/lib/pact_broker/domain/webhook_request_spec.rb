require 'spec_helper'
require 'pact_broker/domain/webhook_request'
require 'webmock/rspec'

module PactBroker

  module Domain

    describe WebhookRequest do

      let(:username) { nil }
      let(:password) { nil }
      let(:url) { 'http://example.org/hook' }
      let(:body) { 'body' }
      let(:logs) { StringIO.new }
      let(:execution_logger) { Logger.new(logs) }
      let(:options) { {failure_log_message: 'oops'}}

      subject do
        WebhookRequest.new(
          method: 'post',
          url: url,
          headers: {'Content-Type' => 'text/plain', 'Authorization' => 'foo'},
          username: username,
          password: password,
          body: body)
      end

      let(:logs) { subject.execute(options).logs }

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
            to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
        end

        it "executes the configured request" do
          subject.execute(options)
          expect(http_request).to have_been_made
        end

        it "logs the request" do
          allow(PactBroker.logger).to receive(:info)
          expect(PactBroker.logger).to receive(:info).with(/POST.*example.*text.*body/)
          subject.execute(options)
        end

        it "logs the response" do
          allow(PactBroker.logger).to receive(:info)
          allow(PactBroker.logger).to receive(:debug)
          expect(PactBroker.logger).to receive(:info).with(/response.*302/)
          expect(PactBroker.logger).to receive(:debug).with(/respbod/)
          subject.execute(options)
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
            expect(logs).to include "HTTP/1.0 302"
          end

          it "logs the response headers" do
            expect(logs).to include "Content-Type: text/foo, blah"
          end

          it "logs the response body" do
            expect(logs).to include "respbod"
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

        context "when a username and password are specified" do

          let(:username) { 'username' }
          let(:password) { 'password' }

          let!(:http_request_with_basic_auth) do
            stub_request(:post, "http://example.org/hook").
              with(
                basic_auth: [username, password],
                :headers => {'Content-Type'=>'text/plain'},
                :body => 'body').
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "uses the credentials" do
            subject.execute(options)
            expect(http_request_with_basic_auth).to have_been_made
          end
        end

        context "when the URL has a https scheme" do
          let(:url) { 'https://example.org/hook' }

          let!(:https_request) do
            # webmock will set the request signature scheme to 'https' _only_ if the use_ssl option is set
            stub_request(:post, "https://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "uses SSL" do
            subject.execute(options)
            expect(https_request).to have_been_made
          end
        end

        context "when the request has a JSONable body" do
          let(:body) { [{"some": "json"}] }

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => body.to_json).
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "converts the body to JSON before submitting the request" do
            subject.execute(options)
            expect(http_request).to have_been_made
          end
        end

        context "when the request has a nil body" do
          let(:body) { nil }

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => nil).
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
          end

          it "executes the request without a body" do
            subject.execute(options)
            expect(http_request).to have_been_made
          end
        end

        context "when the request is successful" do
          it "returns a WebhookExecutionResult with success=true" do
            expect(subject.execute(options).success?).to be true
          end

          it "sets the response on the result" do
            expect(subject.execute(options).response).to be_instance_of(Net::HTTPFound)
          end
        end

        context "when the request is not successful" do

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 500, :body => "An error")
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(subject.execute(options).success?).to be false
          end

          it "sets the response on the result" do
            expect(subject.execute(options).response).to be_instance_of(Net::HTTPInternalServerError)
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
            subject.execute(options)
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(subject.execute(options).success?).to be false
          end

          it "returns a WebhookExecutionResult with an error" do
            expect(subject.execute(options).error).to be_instance_of WebhookTestError
          end

          it "logs the failure_log_message" do
            expect(logs).to include "oops"
          end
        end
      end
    end
  end
end
