require 'pact_broker/pacts/sort_content'

module PactBroker
  module Pacts
    describe SortContent do
      let(:pact_content_1) do
        {
          'a' => 1,
          'interactions' => [{ 'a' => 1, 'b' => 2 }, { 'a' => [2, 1, 3], 'b' => 3 }]
        }
      end

      let(:pact_content_2) do
        {
          'interactions' => [{ 'b' => 3, 'a' => [2, 1, 3]}, { 'b' => 2, 'a' => 1 }],
          'a' => 1
        }
      end

      let(:expected_sorted_content) do
        '{"a":1,"interactions":[{"a":1,"b":2},{"a":[2,1,3],"b":3}]}'
      end

      it "sorts the interactions/messages and keys in a deterministic way" do
        expect(SortContent.call(pact_content_1).to_json).to eq(expected_sorted_content)
        expect(SortContent.call(pact_content_2).to_json).to eq(expected_sorted_content)
      end

      context "when there is no messages or interactions key" do
        let(:other_content) do
          {
            'z' => 1,
            'a' => 1,
            'b' => 1,
          }
        end

        it "does not change the content" do
          expect(SortContent.call(other_content)).to eq other_content
        end
      end
    end
  end
end
