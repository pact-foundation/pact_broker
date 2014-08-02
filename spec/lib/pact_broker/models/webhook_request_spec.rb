require 'spec_helper'
require 'pact_broker/models/webhook_request'
require 'webmock/rspec'

module PactBroker

  module Models

    describe WebhookRequest do

      subject { WebhookRequest.new(method: 'POST',
        url: 'http://example.org/hook',
        headers: [WebhookRequestHeader.new('Content-type', 'text/plain')],
        body: 'body')}

      describe "execute" do

        let!(:http_request) do
          stub_request(:post, "http://example.org/hook").
            with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
            to_return(:status => 200, :body => "respbod", :headers => {})
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
          expect(PactBroker.logger).to receive(:info).with(/response.*200.*respbod/)
          subject.execute
        end

        context "when the request is successful" do
          it "returns true" do
            expect(subject.execute).to be true
          end
        end

        context "when the request is not successful" do

          let!(:http_request) do
            stub_request(:post, "http://example.org/hook").
              with(:headers => {'Content-Type'=>'text/plain'}, :body => 'body').
              to_return(:status => 500, :body => "An error")
          end

          it "raises an error" do
            expect { subject.execute }.to raise_error WebhookRequestError, /500.*An error/
          end
        end

      end

    end

  end

end
