
require 'support/provider_state_builder'

module PactBroker::Api

  module Resources

    describe PactWebhooks do

      before do
        ProviderStateBuilder.new.create_pact_with_hierarchy("Some Consumer", "1", "Some Provider")
      end


      let(:path) { "/webhooks/provider/Some%20Provider/consumer/Some%20Consumer" }
      let(:headers) { {'CONTENT_TYPE' => 'application/json'} }

      describe "POST" do

        subject { post path, webhook_json, headers }

        context "with invalid attributes" do

          let(:errors) { {:request=>["can't be blank"]} }

          let(:webhook_json) do
            {

            }.to_json
          end

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

        xcontext "with valid attributes" do

          let(:webhook_response_json) { {some: 'webhook'}.to_json }
          let(:decorator) { instance_double(Decorators::WebhookDecorator) }

          before do
            allow_any_instance_of(Decorators::WebhookDecorator).to receive(:to_json).and_return(webhook_response_json)
          end

          it "saves the webhook" do
            expect(PactBroker::Services::WebhookService).to receive(:create).with(next_uuid, webhook, consumer, provider)
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
            expect(last_response.headers['Content-Type']).to eq 'application/hal+json'
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
