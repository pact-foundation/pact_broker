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
      let(:logger) { double('logger').as_null_object }

      subject do
        WebhookRequest.new(
          method: 'post',
          url: url,
          headers: headers,
          username: username,
          password: password,
          body: body)
      end

      let(:execute) { subject.execute }

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
            to_return(:status => status, :body => "respbod", :headers => {'Content-Type' => 'text/foo, blah'})
        end

        before do
          allow(WebhookRequest).to receive(:logger).and_return(logger)
          allow(WebhookRequest.logger).to receive(:info)
          allow(WebhookRequest.logger).to receive(:debug)
        end

        let(:status) { 200 }
        let(:request_body) { 'reqbody' }

        it "executes the configured request" do
          execute
          expect(http_request).to have_been_made
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
          it "returns the response" do
            expect(execute.response).to be_instance_of(Net::HTTPOK)
          end
        end

        context "when the request is not successful" do

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'reqbody').
              to_return(:status => 500, :body => "An error")
          end

          it "returns the response" do
            expect(execute.response).to be_instance_of(Net::HTTPInternalServerError)
          end
        end

        context "when an error occurs executing the request" do
          class WebhookTestError < StandardError; end

          before do
            allow(Net::HTTP).to receive(:start).and_raise(WebhookTestError.new("blah"))
            allow(logger).to receive(:error)
          end

          it "returns a WebhookExecutionResult with an error" do
            expect { execute }.to raise_error WebhookTestError
          end
        end
      end
    end
  end
end
