require 'pact_broker/secrets/secret'

module PactBroker
  module Secrets
    describe Secret do
      before do
        allow(PactBroker.configuration.secrets_encryption_key_finder).to receive(:call).and_return(key)
      end

      let(:base64_encoded_key) { "ttDJ1PnVbxGWhIe3T12UHoEfHKB4AvoxdW0JWOg98gE=" }
      let(:key) { Base64.strict_decode64(base64_encoded_key) }
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
    end
  end
end
