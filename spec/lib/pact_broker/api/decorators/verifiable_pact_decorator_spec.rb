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
            "pending" => true,
            "_links" => {
              "self" => {
                "href" => "/pact-version-url",
                "name" => "name"
              }
            }
          }
        end

        let(:decorator) { VerifiablePactDecorator.new(pact) }
        let(:pact) { double('pact', pending: true, name: "name") }
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
