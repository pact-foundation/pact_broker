require "pact_broker/versions/abbreviate_number"

module PactBroker
  module Versions
    describe AbbreviateNumber do
      describe "#call" do
        TEST_CASES = [
          ["202326572516dea6998a7f311fcaa161c0768fc2", "2023265"],
          ["1.2.3+areallyreallyreallylongexplanation", "1.2.3+areallyreallyreallylongexplanation"],
          ["2516dea6998a7f", "2516dea6998a7f"],
          ["1.2.3+202326572516dea6998a7f311fcaa161c0768fc2", "1.2.3+2023265"],
          ["this-is-very-long-text-this-is-very-long-text-this-is-very-long-text-this-is-very-long-text", "this-is-very-long-text-this-is-very-lon…-long-text"]
        ]

        TEST_CASES.each do |(input, output)|
          it "shortens #{input} to #{output}" do
            expect(AbbreviateNumber.call(input)).to eq output
          end
        end
      end
    end
  end
end
