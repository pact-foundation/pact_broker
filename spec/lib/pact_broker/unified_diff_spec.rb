require "pact_broker/unified_diff"

module PactBroker
  describe UnifiedDiff do
    describe ".call" do
      context "when the texts are equal" do
        it "returns an empty string" do
          expect(UnifiedDiff.call("a\nb\n", "a\nb\n")).to eq ""
        end
      end

      context "with one changed line" do
        let(:old_text) { "{\n  \"a\": 1\n}" }
        let(:new_text) { "{\n  \"a\": 2\n}" }

        it "renders one hunk with context lines" do
          expected = <<~DIFF.chomp
            @@ -1,3 +1,3 @@
             {
            -  "a": 1
            +  "a": 2
             }
          DIFF
          expect(UnifiedDiff.call(old_text, new_text)).to eq expected
        end
      end

      context "with two changes closer together than the context" do
        let(:old_text) { (1..8).map(&:to_s).join("\n") }
        let(:new_text) { old_text.sub("3\n", "three\n").sub("5\n", "five\n") }

        it "merges them into a single hunk" do
          expected = <<~DIFF.chomp
            @@ -1,8 +1,8 @@
             1
             2
            -3
            +three
             4
            -5
            +five
             6
             7
             8
          DIFF
          expect(UnifiedDiff.call(old_text, new_text)).to eq expected
        end
      end

      context "with two changes further apart than the context" do
        let(:old_text) { (1..20).map(&:to_s).join("\n") }
        let(:new_text) { old_text.sub("2\n", "two\n").sub("19\n", "nineteen\n") }

        it "renders two hunks" do
          diff = UnifiedDiff.call(old_text, new_text)
          expect(diff.scan(/^@@/).size).to eq 2
          expect(diff).to include("-2\n+two\n")
          expect(diff).to include("-19\n+nineteen\n")
        end

        it "honours the context width" do
          diff = UnifiedDiff.call(old_text, new_text, context: 0)
          expect(diff.lines.grep(/^ /)).to be_empty
        end
      end
    end
  end
end
