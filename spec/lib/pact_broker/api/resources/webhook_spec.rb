require 'spec_helper'
require 'pact_broker/api/resources/webhook'

module PactBroker::Api

  module Resources

    describe Webhook do

      before do
        allow(PactBroker::Webhooks::Service).to receive(:find_by_uuid).and_return(webhook)
      end

      describe "GET" do
        subject { get '/webhooks/some-uuid'; last_response }

        context "when the webhook does not exist" do
          let(:webhook) { nil }

          it "returns a 404" do
            expect(subject).to be_a_404_response
          end
        end

        context "when the webhook exists" do

          let(:webhook) { double("webhook") }
          let(:decorator) { double(Decorators::WebhookDecorator, to_json: json)}
          let(:json) { {some: 'json'}.to_json }

          before do
            allow(Decorators::WebhookDecorator).to receive(:new).and_return(decorator)
          end

          it "finds the webhook by UUID" do
            expect(PactBroker::Webhooks::Service).to receive(:find_by_uuid).with('some-uuid')
            subject
          end

          it "returns a 200 JSON response" do
            subject
            expect(last_response).to be_a_hal_json_success_response
          end

          it "generates a JSON representation of the webhook" do
            expect(Decorators::WebhookDecorator).to receive(:new).with(webhook)
            expect(decorator).to receive(:to_json).with(user_options: { base_url: 'http://example.org'})
            subject
          end

          it "includes the JSON representation in the response body" do
            subject
            expect(last_response.body).to eq json
          end
        end
      end

      describe "PUT" do
        context "when the webhook does not exist" do
          let(:webhook) { nil }
          let(:webhook_json) { load_fixture('webhook_valid.json') }

          subject { put '/webhooks/some-uuid', webhook_json, {'CONTENT_TYPE' => 'application/json'}; last_response }

          it "returns a 404" do
            expect(subject).to be_a_404_response
          end
        end
      end
    end
  end
end
