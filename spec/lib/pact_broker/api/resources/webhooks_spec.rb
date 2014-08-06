require 'pact_broker/api/resources/webhooks'

module PactBroker::Api

  module Resources

    describe Webhooks do

      describe "POST" do
        let(:webhook_json) do
          {
            some: 'json'
          }.to_json
        end

        let(:uuid) { '1483234k24DKFGJ45K' }
        let(:path) { "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer" }
        let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
        let(:webhook) { double('webhook')}
        let(:saved_webhook) { double('saved_webhook', uuid: 'webhook-uuid')}
        let(:provider) { instance_double(PactBroker::Models::Pacticipant)}
        let(:consumer) { instance_double(PactBroker::Models::Pacticipant)}
        let(:errors) { [] }

        before do
          allow(PactBroker::Services::WebhookService).to receive(:create).and_return(saved_webhook)
          allow(PactBroker::Services::PacticipantService).to receive(:find_pacticipant_by_name).with("Some Provider").and_return(provider)
          allow(PactBroker::Services::PacticipantService).to receive(:find_pacticipant_by_name).with("Some Consumer").and_return(consumer)
          allow(webhook).to receive(:validate).and_return(errors)
          allow(PactBroker::Models::Webhook).to receive(:new).and_return(webhook)
        end

        subject { post path, webhook_json, headers }

        context "with malformed JSON" do
          let(:webhook_json) { "{" }

          it "returns a 400 error" do
            subject
            expect(last_response.status).to eq 400
          end
        end

        context "when the provider is not found" do
          let(:provider) { nil }
          it "returns a 404 status" do
            subject
            expect(last_response.status).to eq 404
          end

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/json'
          end

          it "returns an error message" do
            subject
            expect(JSON.parse(last_response.body, symbolize_names: true)).to eq error: "No provider with name 'Some Provider' found"
          end
        end

        context "when the consumer is not found" do
          let(:consumer) { nil }
          it "returns a 404 status" do
            subject
            expect(last_response.status).to eq 404
          end

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/json'
          end

          it "returns an error message" do
            subject
            expect(JSON.parse(last_response.body, symbolize_names: true)).to eq error: "No consumer with name 'Some Consumer' found"
          end
        end


        context "with invalid attributes" do

          let(:errors) { ['errors'] }

          it "returns a 400" do
            subject
            expect(last_response.status).to be 400
          end

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/json'
          end

          it "returns the validation errors" do
            subject
            expect(JSON.parse(last_response.body, symbolize_names: true)).to eq errors: errors
          end

        end

        context "with valid attributes" do

          let(:webhook_response_json) { {some: 'webhook'}.to_json }
          let(:decorator) { instance_double(Decorators::WebhookDecorator) }

          before do
            allow_any_instance_of(Decorators::WebhookDecorator).to receive(:to_json).and_return(webhook_response_json)
          end

          it "saves the webhook" do
            expect(PactBroker::Services::WebhookService).to receive(:create).with(webhook, consumer, provider)
            subject
          end

          it "returns a 201 response" do
            subject
            expect(last_response.status).to be 201
          end

          it "returns the Location header" do
            subject
            expect(last_response.headers['Location']).to include('webhook-uuid')
          end

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/json'
          end

          it "generates the JSON response body" do
            allow(Decorators::WebhookDecorator).to receive(:new).and_call_original #Deserialise
            expect(Decorators::WebhookDecorator).to receive(:new).with(saved_webhook).and_return(decorator) #Serialize
            expect(decorator).to receive(:to_json).with(base_url: 'http://example.org')
            subject
          end

          it "returns the JSON representation of the webhook" do
            subject
            expect(last_response.body).to eq webhook_response_json
          end
        end

      end

    end
  end

end
