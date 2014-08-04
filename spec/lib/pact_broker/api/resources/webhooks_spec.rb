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
        let(:webhook) { instance_double(PactBroker::Models::Webhook)}
        let(:provider) { instance_double(PactBroker::Models::Pacticipant)}
        let(:consumer) { instance_double(PactBroker::Models::Pacticipant)}
        before do
          #allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid)
          allow_any_instance_of(PactBroker::Repositories::WebhookRepository).to receive(:create).and_return(webhook)
          allow(PactBroker::Services::PacticipantService).to receive(:find_pacticipant_by_name).with("Some Provider").and_return(provider)
          allow(PactBroker::Services::PacticipantService).to receive(:find_pacticipant_by_name).with("Some Consumer").and_return(consumer)
        end

        subject { post path, webhook_json, headers }

        it "creates a webhook"

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

          before do
            allow_any_instance_of(PactBroker::Models::Webhook).to receive(:validate).and_return(errors)
          end

          it "returns a 400"

        end

      end



    end
  end

end
