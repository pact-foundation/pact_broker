require 'pact_broker/api/resources/secrets'

module PactBroker
  module Api
    module Resources
      describe Secrets do
        include_context "stubbed services"

        before do
          allow(secret_service).to receive(:next_uuid).and_return('next-uuid')
          allow(secret_service).to receive(:create).and_return(created_unencrypted_secret)
          allow(secret_service).to receive(:encryption_key_configured?).and_return(encryption_key_configured)
          allow(Decorators::SecretDecorator).to receive(:new).and_return(secret_decorator)
          allow(Contracts::SecretContract).to receive(:new).and_return(secret_contract)
        end

        let(:rack_headers) do
          {
            "pactbroker.secrets_encryption_key_id" => "foo",
            "CONTENT_TYPE" => "application/json",
            "HTTP_ACCEPT" => "application/hal+json"

          }
        end
        let(:request_body) do
          {
            name: "name",
            value: "value"
          }.to_json
        end
        let(:errors) { {} }
        let(:response_body) { 'response-body' }
        let(:unencrypted_secret) { double('unencrypted_secret').as_null_object }
        let(:created_unencrypted_secret) { double('created_unencrypted_secret').as_null_object }
        let(:secret_decorator) do
          instance_double(Decorators::SecretDecorator, from_json: unencrypted_secret, to_json: response_body)
        end
        let(:secret_contract) do
          instance_double(Contracts::SecretContract, validate: errors.empty?, errors: errors)
        end
        let(:encryption_key_configured) { true }

        subject { post("/secrets", request_body, rack_headers) }

        it "checks that the encryption key is set" do
          expect(secret_service).to receive(:encryption_key_configured?).with("foo")
          subject
        end

        it "creates the secret" do
          expect(secret_service).to receive(:create).with("next-uuid", unencrypted_secret, "foo")
          subject
        end

        it "returns a 200" do
          expect(subject).to be_a_hal_json_created_response
        end

        context "when there are validation errors" do
          let(:errors) { { "field" => "name" } }

          it "returns an error response" do
            expect(subject).to be_a_json_error_response("field")
          end
        end
      end
    end
  end
end
