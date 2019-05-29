require 'pact_broker/api/decorators/verifiable_pact_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactDecorator do
        before do
          allow(decorator).to receive(:pact_version_url).and_return('/pact-version-url')
        end
        let(:expected_hash) do
          {
            "verificationProperties" => {
              "pending" => true,
              "pendingReason" => Pact.like("message"),
              "inclusionReason" => Pact.like("message")
            },
            "_links" => {
              "self" => {
                "href" => "/pact-version-url",
                "name" => "name"
              }
            }
          }
        end

        let(:decorator) { VerifiablePactDecorator.new(pact) }
        let(:pact) do
          double('pact',
            pending: true,
            name: "name",
            provider_name: "Bar",
            pending_provider_tags: pending_provider_tags,
            consumer_tags: consumer_tags)
        end
        let(:pending_provider_tags) { %w[dev] }
        let(:consumer_tags) { %w[dev] }
        let(:json) { decorator.to_json(options) }
        let(:options) { { user_options: { base_url: 'http://example.org' } } }

        subject { JSON.parse(json) }

        it "generates a matching hash" do
          expect(subject).to match_pact(expected_hash)
        end

        it "creates the pact version url" do
          expect(decorator).to receive(:pact_version_url).with(pact, 'http://example.org')
          subject
        end
      end
    end
  end
end
