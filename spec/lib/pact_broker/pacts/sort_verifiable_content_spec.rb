require 'pact_broker/pacts/sort_verifiable_content'

module PactBroker
  module Pacts
    describe SortVerifiableContent do
      let(:pact_content_1) do
        {
          a: 1,
          interactions: [{ a: 1, b: 2 }, { a: 2, b: 3 }]
        }.to_json
      end

      let(:pact_content_2) do
        {
          interactions: [{ b: 3, a: 2}, { b: 2, a: 1 }],
          a: 1
        }.to_json
      end

      it "sorts the interactions/messages and keys in a deterministic way" do
        expect(SortVerifiableContent.call(pact_content_1).to_json).to eq(SortVerifiableContent.call(pact_content_2).to_json)
      end
    end
  end
end
