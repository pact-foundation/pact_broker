require 'pact_broker/api/resources/secret'

module PactBroker
  module Api
    module Resources
      describe Secret do
        include_context "stubbed services"

        before do
          allow(secret_service).to receive(:encryption_key_configured?).and_return(encryption_key_configured)
          allow(secret_service).to receive(:find_by_uuid).and_return(secret)
        end

        let(:path) { "/secrets/#{uuid}" }
        let(:uuid) { "uuid" }
        let(:request_body) { { name: "updated name", value: "updated value" }.to_json }
        let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json"} }
        let(:response_body_hash) { JSON.parse(subject.body) }
        let(:encryption_key_configured) { true }
        let(:secret) { double('secret') }

        subject { put(path, request_body, rack_headers) }

        context "when the encryption key is not configured" do
          let(:encryption_key_configured) { false }

          it "returns a 409" do
            expect(subject.status).to eq 409
          end

          it "returns an error message" do
            expect(response_body_hash["error"]["message"]).to include "has not been configured"
          end
        end
      end
    end
  end
end
