require 'pact_broker/api/resources/pact_webhooks'

module PactBroker::Api

  module Resources

    describe PactWebhooks do


      let(:webhook_service) { PactBroker::Webhooks::Service }
      let(:uuid) { '1483234k24DKFGJ45K' }
      let(:path) { "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer" }
      let(:headers) { {'CONTENT_TYPE' => 'application/json'} }
      let(:webhook) { double('webhook')}
      let(:saved_webhook) { double('saved_webhook')}
      let(:provider) { instance_double(PactBroker::Domain::Pacticipant)}
      let(:consumer) { instance_double(PactBroker::Domain::Pacticipant)}

      before do
        allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Some Provider").and_return(provider)
        allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Some Consumer").and_return(consumer)
      end

      describe "GET" do
        let(:webhooks) { double('webhooks') }
        let(:json) { {some: 'webhooks'}.to_json }
        let(:decorator) { instance_double(Decorators::WebhooksDecorator, to_json: json) }

        before do
          allow(webhook_service).to receive(:find_by_consumer_and_provider).and_return(webhooks)
          allow(Decorators::WebhooksDecorator).to receive(:new).and_return(decorator)
        end

        subject { get path }

        it "returns a 200 HAL JSON response" do
          subject
          expect(last_response).to be_a_hal_json_success_response
        end

        it "generates a JSON body" do
          expect(Decorators::WebhooksDecorator).to receive(:new).with(webhooks)
          expect(decorator).to receive(:to_json).with(user_options: instance_of(Decorators::DecoratorContext))
          subject
        end

        it "includes the generated JSON in the response body" do
          subject
          expect(last_response.body).to eq json
        end


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

        context "when the provider is not found" do
          let(:provider) { nil }
          it "returns a 404 status" do
            subject
            expect(last_response.status).to eq 404
          end

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/json;charset=utf-8'
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
            expect(last_response.headers['Content-Type']).to eq 'application/json;charset=utf-8'
          end

          it "returns an error message" do
            subject
            expect(JSON.parse(last_response.body, symbolize_names: true)).to eq error: "No consumer with name 'Some Consumer' found"
          end
        end


        context "with invalid attributes" do

          let(:valid) { false }

          it "returns a 400" do
            subject
            expect(last_response.status).to be 400
          end

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/json;charset=utf-8'
          end

          it "returns the validation errors" do
            subject
            expect(JSON.parse(last_response.body, symbolize_names: true)).to eq errors: ['messages']
          end

        end

        context "with valid attributes" do

          let(:webhook_response_json) { {some: 'webhook'}.to_json }
          let(:decorator) { instance_double(Decorators::WebhookDecorator) }

          before do
            allow_any_instance_of(Decorators::WebhookDecorator).to receive(:to_json).and_return(webhook_response_json)
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

          it "returns a JSON content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json;charset=utf-8'
          end

          it "generates the JSON response body" do
            allow(Decorators::WebhookDecorator).to receive(:new).and_call_original #Deserialise
            expect(Decorators::WebhookDecorator).to receive(:new).with(saved_webhook).and_return(decorator) #Serialize
            expect(decorator).to receive(:to_json).with(user_options: { base_url: 'http://example.org' })
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
