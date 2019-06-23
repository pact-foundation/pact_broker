require 'pact_broker/secrets/secret'

describe "Deleting a secret", secret_key: true do
  let!(:secret) { td.create_secret.and_return(:secret) }
  let(:path) { "/secrets/#{secret.uuid}" }

  subject { delete(path)  }

  context "when the secret exists" do
    it "returns a 204 No Content" do
      expect(subject.status).to be 204
    end

    it "deletes the secret" do
      expect { subject }.to change { PactBroker::Secrets::Secret.count }.by(-1)
    end
  end
end
