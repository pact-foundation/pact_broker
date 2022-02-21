require "pact_broker/string_refinements"

module PactBroker
  describe StringRefinements do
    using StringRefinements

    describe "ellipsisize" do
      let(:very_long_string) do
        "This is a very long string. May be too long to be true. It should be truncated in the middle"
      end

      context "when using default value to truncate the string" do
        it "truncates the string in the middle to the default length" do
          expect(very_long_string.ellipsisize).to eq("This is a ...the middle")
        end
      end

      context "when using customised value to truncate the string" do
        it "truncates the string in the middle to the customised length" do
          expect(very_long_string.ellipsisize(edge_length: 15)).to eq("This is a very ...d in the middle")
        end
      end
    end
  end
end
