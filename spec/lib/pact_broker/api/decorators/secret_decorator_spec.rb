require 'pact_broker/api/decorators/secret_decorator'
require 'pact_broker/secrets/unencrypted_secret'

module PactBroker
  module Api
    module Decorators
      describe SecretDecorator do
        before do
          allow(decorator).to receive(:secret_url).and_return('secret_url')
        end
        let(:decorator) { SecretDecorator.new(secret) }
        let(:secret) do
          instance_double("PactBroker::Secrets::UnencryptedSecret",
            name: "name",
            description: "description",
            value: "the secret",
            created_at: time,
            updated_at: time + 1
          )
        end

        let(:time) { in_utc{ DateTime.new(2019, 1, 1) } }

        let(:expected_hash) do
          {
            "name" => "name",
            "description" => "description",
            "createdAt" => "2019-01-01T00:00:00+00:00",
            "updatedAt" => "2019-01-02T00:00:00+00:00",
            "_links" => {
              "self" => {
                "href" => "secret_url",
              }
            }
          }
        end

        let(:user_options) do
          {
            base_url: 'http://example.org',
            resource_url: 'http://example.org/provider-pacts',
          }
        end

        subject { decorator.to_hash(user_options: user_options) }

        describe "to_hash" do
          it "creates the secret url" do
            expect(decorator).to receive(:secret_url).with(secret, 'http://example.org')
            subject
          end

          it "creates a hash" do
            expect(subject).to match_pact(expected_hash, { allow_unexpected_keys: false })
          end

          it "does not include the secret value" do
            expect(subject).to_not have_key("value")
          end
        end

        describe "from_hash" do
          before do
            allow(PactBroker.configuration.secrets_encryption_key_finder).to receive(:call).and_return('foo')
          end
          let(:hash) do
            {
              "name" => "name",
              "description" => "description",
              "value" => "the secret"
            }
          end

          subject { SecretDecorator.new(PactBroker::Secrets::UnencryptedSecret.new).from_hash(hash) }

          its(:name) { is_expected.to eq "name" }
          its(:description) { is_expected.to eq "description" }
          its(:value) { is_expected.to eq "the secret" }
        end
      end
    end
  end
end
