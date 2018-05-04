require 'pact_broker/pacts/sort_verifiable_content'

module PactBroker
  module Pacts
    describe SortVerifiableContent do
      let(:pact_content_1) do
        {
          a: 1,
          interactions: [{ a: [2, 1], b: 2 }, { x: 2, y: 3 }]
        }.to_json
      end

      let(:pact_content_2) do
        {
          interactions: [{ y: 3, x: 2}, { b: 2, a: [2, 1] }],
          a: 1
        }.to_json
      end

      it "sorts the interactions/messages and keys in a deterministic way" do
        expect(SortVerifiableContent.call(pact_content_1)).to eq(SortVerifiableContent.call(pact_content_2))
      end

      it "does not change the order of the child hashes" do
        array = JSON.parse(SortVerifiableContent.call(pact_content_1)).first['a']
        expect(array).to eq [2, 1]
      end

      context "when there is no messages or interactions key" do
        let(:other_content) do
          {
            z: 1,
            a: 1,
            b: 1,
          }.to_json
        end

        it "does not change the content" do
          expect(SortVerifiableContent.call(other_content)).to eq other_content
        end
      end

      context "when the interactions/messages is a hash" do
        let(:pact_content_1) do
          {
            a: 1,
            interactions: {
              z: [{ b: 2, a: 1 }, { b: 3, a: 2 }]
            }
          }.to_json
        end

        let(:pact_content_2) do
          {
            a: 1,
            interactions: {
              z: [{ a: 1, b: 2 }, { a: 2, b: 3 }]
            }
          }.to_json
        end

        it "sorts the hashes" do
          expect(SortVerifiableContent.call(pact_content_1)).to eq(SortVerifiableContent.call(pact_content_2))
        end
      end
    end
  end
end
