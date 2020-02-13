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
          before do
            allow(Decorators::WebhookDecorator).to receive(:new).and_return(decorator)
          end

          let(:webhook) { double("webhook") }
          let(:decorator) { double(Decorators::WebhookDecorator, to_json: json)}
          let(:json) { {some: 'json'}.to_json }

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
        before do
          allow(Decorators::WebhookDecorator).to receive(:new).and_return(decorator)
          allow(PactBroker::Webhooks::Service).to receive(:create).and_return(created_webhook)
          allow_any_instance_of(Webhook).to receive(:consumer).and_return(consumer)
          allow_any_instance_of(Webhook).to receive(:provider).and_return(provider)
          allow_any_instance_of(Webhook).to receive(:webhook_validation_errors?).and_return(false)
        end

        let(:consumer) { double('consumer') }
        let(:provider) { double('provider') }
        let(:webhook) { double("webhook") }
        let(:decorator) { double(Decorators::WebhookDecorator, from_json: parsed_webhook, to_json: json)}
        let(:json) { {some: 'json'}.to_json }

        let(:parsed_webhook) { double('parsed_webhook') }
        let(:created_webhook) { double('created_webhook') }
        let(:webhook) { nil }
        let(:webhook_json) { load_fixture('webhook_valid.json') }
        let(:uuid) { 'some-uuid' }

        subject { put("/webhooks/#{uuid}", webhook_json, 'CONTENT_TYPE' => 'application/json') }

        it "validates the UUID" do
          expect_any_instance_of(Webhook).to receive(:webhook_validation_errors?).with(parsed_webhook, uuid)
          subject
        end

        context "when the webhook does not exist" do
          it "creates the webhook" do
            expect(PactBroker::Webhooks::Service).to receive(:create).with(uuid, parsed_webhook, consumer, provider)
            subject
          end

          its(:status) { is_expected.to eq 201 }

          it "returns the JSON respresentation of the webhook" do
            expect(subject.body).to eq json
          end
        end

        context "when the webhook does exist" do
          before do
            allow(PactBroker::Webhooks::Service).to receive(:update_by_uuid).and_return(created_webhook)
          end
          let(:webhook) { double('existing webhook') }

          its(:status) { is_expected.to eq 200 }

          it "updates the webhook" do
            expect(PactBroker::Webhooks::Service).to receive(:update_by_uuid).with(uuid, JSON.parse(webhook_json))
            subject
          end

          it "returns the JSON respresentation of the webhook" do
            expect(subject.body).to eq json
          end
        end
      end
    end
  end
end
