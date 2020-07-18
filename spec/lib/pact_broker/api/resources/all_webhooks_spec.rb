require 'spec_helper'
require 'pact_broker/api/resources/all_webhooks'

module PactBroker::Api

  module Resources

    describe AllWebhooks do

      let(:webhook_service) { PactBroker::Webhooks::Service }
      let(:uuid) { '1483234k24DKFGJ45K' }
      let(:path) { "/webhooks" }
      let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
      let(:webhook) { double('webhook', consumer: parsed_consumer, provider: parsed_provider) }
      let(:parsed_provider) { instance_double(PactBroker::Domain::Pacticipant, name: "Some Provider") }
      let(:parsed_consumer) { instance_double(PactBroker::Domain::Pacticipant, name: "Some Consumer") }
      let(:consumer) { double('consumer', name: "Some Consumer") }
      let(:provider) { double('provider', name: "Some Provider") }
      let(:saved_webhook) { double('saved_webhook')}
      let(:webhook_decorator) { instance_double(Decorators::WebhookDecorator, from_json: webhook) }

      before do
        allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Some Provider").and_return(provider)
        allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Some Consumer").and_return(consumer)
        allow(Decorators::WebhookDecorator).to receive(:new).and_return(webhook_decorator)
      end

      describe "POST" do
        let(:webhook_json) do
          {
            some: 'json'
          }.to_json
        end

        let(:next_uuid) { '123k2nvkkwjrwk34' }
        let(:valid) { true }
        let(:errors) { double("errors", empty?: valid, messages: ['messages']) }

        before do
          allow(webhook_service).to receive(:create).and_return(saved_webhook)
          allow(webhook_service).to receive(:next_uuid).and_return(next_uuid)
          allow(webhook_service).to receive(:errors).and_return(errors)
          allow(PactBroker::Domain::Webhook).to receive(:new).and_return(webhook)
        end

        subject { post path, webhook_json, headers }

        context "with malformed JSON" do
          let(:webhook_json) { "{" }

          it "returns a 400 error" do
            subject
            expect(last_response.status).to eq 400
          end
        end

        context "with invalid attributes" do

          let(:valid) { false }

          it "returns a 400" do
            subject
            expect(last_response.status).to be 400
          end

          it "returns a HAL JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
          end

          it "returns the validation errors" do
            subject
            expect(JSON.parse(last_response.body, symbolize_names: true)).to eq errors: ['messages']
          end

        end

        context "with valid attributes" do

          let(:webhook_response_json) { { some: 'webhook' }.to_json }

          before do
            allow_any_instance_of(Decorators::WebhookDecorator).to receive(:to_json).and_return(webhook_response_json)
            allow(webhook_decorator).to receive(:to_json).and_return(webhook_response_json)
          end

          it "saves the webhook" do
            expect(webhook_service).to receive(:create).with(next_uuid, webhook, consumer, provider)
            subject
          end

          it "returns a 201 response" do
            subject
            expect(last_response.status).to be 201
          end

          it "returns the Location header" do
            subject
            expect(last_response.headers['Location']).to include(next_uuid)
          end

          it "returns a HAL JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
          end

          it "generates the JSON response body" do
            expect(Decorators::WebhookDecorator).to receive(:new).with(saved_webhook).and_return(webhook_decorator)
            expect(webhook_decorator).to receive(:to_json).with(user_options: hash_including({ base_url: 'http://example.org' }))
            subject
          end

          it "returns the JSON representation of the webhook" do
            subject
            expect(last_response.body).to eq webhook_response_json
          end
        end
      end

      describe "GET" do

        subject { get "/webhooks" }

        let(:webhooks) { [double('webhook')]}
        let(:decorator) { double(Decorators::WebhooksDecorator, to_json: json)}
        let(:json) { {some: 'json'}.to_json }

        before do
          allow(Decorators::WebhooksDecorator).to receive(:new).and_return(decorator)
          allow(PactBroker::Webhooks::Service).to receive(:find_all).and_return(webhooks)
        end

        it "returns a 200 HAL JSON response" do
          subject
          expect(last_response).to be_a_hal_json_success_response
        end

        it "generates a JSON representation of the webhook" do
          expect(Decorators::WebhooksDecorator).to receive(:new).with(webhooks)
          expect(decorator).to receive(:to_json).with(user_options: instance_of(Decorators::DecoratorContext))
          subject
        end

        it "includes the JSON representation in the response body" do
          subject
          expect(last_response.body).to eq json
        end

      end

    end
  end

end
