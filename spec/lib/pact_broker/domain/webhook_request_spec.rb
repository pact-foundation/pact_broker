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

      subject do
        WebhookRequest.new(
          method: 'post',
          url: url,
          headers: {'Content-type' => 'text/plain'},
          username: username,
          password: password,
          body: body)
      end

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
            to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/plain, blah'})
        end

        it "executes the configured request" do
          subject.execute
          expect(http_request).to have_been_made
        end

        it "logs the request" do
          allow(PactBroker.logger).to receive(:info)
          expect(PactBroker.logger).to receive(:info).with(/POST.*example.*text.*body/)
          subject.execute
        end

        it "logs the response" do
          allow(PactBroker.logger).to receive(:info)
          allow(PactBroker.logger).to receive(:debug)
          expect(PactBroker.logger).to receive(:info).with(/response.*302/)
          expect(PactBroker.logger).to receive(:debug).with(/respbod/)
          subject.execute
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
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/plain, blah'})
          end

          it "uses the credentials" do
            subject.execute
            expect(http_request_with_basic_auth).to have_been_made
          end
        end

        context "when the URL has a https scheme" do
          let(:url) { 'https://example.org/hook' }

          let!(:https_request) do
            # webmock will set the request signature scheme to 'https' _only_ if the use_ssl option is set
            stub_request(:post, "https://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/plain, blah'})
          end

          it "uses SSL" do
            subject.execute
            expect(https_request).to have_been_made
          end
        end

        context "when the request has a JSONable body" do
          let(:body) { [{"some": "json"}] }

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => body.to_json).
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/plain, blah'})
          end

          it "converts the body to JSON before submitting the request" do
            subject.execute
            expect(http_request).to have_been_made
          end
        end

        context "when the request has a nil body" do
          let(:body) { nil }

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => nil).
              to_return(:status => 302, :body => "respbod", :headers => {'Content-Type' => 'text/plain, blah'})
          end

          it "executes the request without a body" do
            subject.execute
            expect(http_request).to have_been_made
          end
        end

        context "when the request is successful" do
          it "returns a WebhookExecutionResult with success=true" do
            expect(subject.execute.success?).to be true
          end

          it "sets the response on the result" do
            expect(subject.execute.response).to be_instance_of(Net::HTTPFound)
          end
        end

        context "when the request is not successful" do

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 500, :body => "An error")
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(subject.execute.success?).to be false
          end

          it "sets the response on the result" do
            expect(subject.execute.response).to be_instance_of(Net::HTTPInternalServerError)
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
            subject.execute
          end

          it "returns a WebhookExecutionResult with success=false" do
            expect(subject.execute.success?).to be false
          end

          it "returns a WebhookExecutionResult with an error" do
            expect(subject.execute.error).to be_instance_of WebhookTestError
          end
        end

      end

    end

  end

end
