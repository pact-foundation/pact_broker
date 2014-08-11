require 'spec_helper'
require 'pact_broker/models/webhook_request'
require 'webmock/rspec'

module PactBroker

  module Models

    describe WebhookRequest do

      subject { WebhookRequest.new(method: 'post',
        url: 'http://example.org/hook',
        headers: {'Content-type' => 'text/plain'},
        body: 'body')}

      describe "description" do
        it "returns a brief description of the HTTP request" do
          expect(subject.description).to eq 'POST example.org'
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
          expect(PactBroker.logger).to receive(:info).with(/response.*302.*respbod/)
          subject.execute
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


      describe "validate" do
        let(:method) { 'POST' }
        let(:url) { "http://example.org" }
        subject { WebhookRequest.new(method: method, url: url)}
        context "with a missing method" do
          let(:method) { nil }
          it "returns an error" do
            expect(subject.validate.first).to eq "Missing required attribute 'method'"
          end
        end
        context "with an invalid method" do
          let(:method) { 'INVALID' }
          it "returns an error" do
            expect(subject.validate.first).to eq "Invalid HTTP method 'INVALID'"
          end
        end
        context "with a missing url" do
          let(:url) { nil }
          it "returns an error" do
            expect(subject.validate.first).to eq "Missing required attribute 'url'"
          end
        end
        context "with a URL that is missing the scheme" do
          let(:url) { "example.org" }
          it "returns an error" do
            expect(subject.validate.first).to eq "Invalid URL 'example.org'. Expected format: http://example.org"
          end
        end

      end
    end

  end

end
