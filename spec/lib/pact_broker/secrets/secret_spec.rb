require 'pact_broker/secrets/secret'

module PactBroker
  module Secrets
    describe Secret do
      before do
        allow(PactBroker.configuration.secrets_encryption_key_finder).to receive(:call).and_return(key)
      end

      let(:key) { SecureRandom.random_bytes(32) }
      let(:params) do
        {
          name: "foo",
          key_id: "default"
        }
      end

      subject { Secret.new(params) }

      it "finds the key" do
        expect(PactBroker.configuration.secrets_encryption_key_finder).to receive(:call).with(key_id: "default")
        subject.value = "bar"
        subject.save
      end

      it "encrypts the value when saving" do
        subject.value = "bar"
        subject.save
        expect(Secret.dataset.first.encrypted_value).to_not eq "bar"
      end

      it "decryptes the value when loaded from the database" do
        subject.value = "bar"
        subject.save
        expect(Secret.find(id: subject.id).value).to eq "bar"
      end

      context "when the value is an empty string" do
        it "doesn't blow up" do
          subject.value = ""
          subject.save
          expect(Secret.find(id: subject.id).value).to eq ""
        end
      end

      context "when the value is nil" do
        it "doesn't blow up" do
          subject.value = nil
          subject.save
          expect(Secret.find(id: subject.id).value).to be nil
        end
      end

      context "when changing the key the secret is encrypted with" do
        let(:key_2) { SecureRandom.random_bytes(32) }

        it "doesn't blow up" do
          expect(PactBroker.configuration.secrets_encryption_key_finder).to receive(:call).and_return(key, key_2)
          subject.value = "bar"
          subject.save
          subject.value = "bar2"
          subject.key_id = "new_key"
          subject.save
        end
      end
    end
  end
end
