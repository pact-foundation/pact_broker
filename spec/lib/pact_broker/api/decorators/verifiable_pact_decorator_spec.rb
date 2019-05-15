require 'pact_broker/api/decorators/verifiable_pact_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactDecorator do

        let(:expected_hash) do
          {
            "pending" => true,
            "_links" => {
              "self" => "http://pact"
            }
          }
        end

        let(:decorator) { VerifiablePactDecorator.new(pact) }
        let(:pact) { double('pact') }
        let(:json) { decorator.to_json(options) }
        let(:options) { { user_options: { base_url: 'http://example.org' } } }

        subject { JSON.parse(json) }

        it "generates a matching hash", pending: true do
          expect(subject).to match_pact(expected_hash)
        end
      end
    end
  end
end
