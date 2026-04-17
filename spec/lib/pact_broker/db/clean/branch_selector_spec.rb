require "pact_broker/db/clean/branch_selector"

module PactBroker
  module DB
    class Clean
      describe BranchSelector do
        describe ".from_hash" do
          it "parses max_age" do
            selector = BranchSelector.from_hash(max_age: 30)
            expect(selector.max_age).to eq 30
          end

          it "parses branch as a single string" do
            selector = BranchSelector.from_hash(branch: "main")
            expect(selector.branch).to eq "main"
          end

          it "parses branch as an array" do
            selector = BranchSelector.from_hash(branch: ["develop", "release"])
            expect(selector.branch).to eq ["develop", "release"]
          end

          it "converts camelCase keys" do
            selector = BranchSelector.from_hash("maxAge" => 60)
            expect(selector.max_age).to eq 60
          end

          it "ignores unknown keys" do
            expect { BranchSelector.from_hash(unknown_key: "value") }.not_to raise_error
          end
        end

        describe "#to_hash" do
          it "includes max_age when set" do
            selector = BranchSelector.new(max_age: 90)
            expect(selector.to_hash).to eq(max_age: 90)
          end

          it "includes branch when set" do
            selector = BranchSelector.new(branch: ["develop"])
            expect(selector.to_hash).to eq(branch: ["develop"])
          end

          it "omits nil attributes" do
            selector = BranchSelector.new(max_age: 30)
            expect(selector.to_hash.keys).not_to include(:branch)
          end
        end

        describe "#to_json" do
          it "serialises to the original source hash when created from a hash" do
            source = { "maxAge" => 30 }
            selector = BranchSelector.from_hash(source)
            expect(selector.to_json).to eq source.to_json
          end

          it "serialises to_hash when created directly" do
            selector = BranchSelector.new(max_age: 30)
            expect(selector.to_json).to eq({ max_age: 30 }.to_json)
          end
        end
      end
    end
  end
end
