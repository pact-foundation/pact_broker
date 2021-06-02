require "pact_broker/matrix/repository"

module PactBroker
  module Matrix
    describe Repository do
      let(:td) { TestDataBuilder.new}

      def build_selectors(hash)
        hash.collect do | key, value |
          UnresolvedSelector.new(pacticipant_name: key, pacticipant_version_number: value)
        end
      end

      def shorten_row row
        "#{row[:consumer_name]}#{row[:consumer_version_number]} #{row[:provider_name]}#{row[:provider_version_number] || '?'} n#{row[:verification_number] || '?'}"
      end

      def shorten_rows rows
        rows.collect{ |r| shorten_row(r) }
      end

      describe "find when deploying a provider to prod for the first time and the consumer has not been deployed yet" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "2")
        end

        let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ] }
        let(:options) { { latest: true, tag: "prod"} }

        subject { shorten_rows(rows) }
        let(:rows) { Repository.new.find(selectors, options) }

        it "returns an empty array" do
          expect(rows).to eq []
        end
      end

      describe "find when deploying a consumer to prod for the first time and the provider has not been deployed yet" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "2")
        end

        let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ] }
        let(:options) { { latest: true, tag: "prod"} }

        subject { shorten_rows(rows) }
        let(:results) { Repository.new.find(selectors, options) }

        it "returns an array with one row that does not have a verification" do
          expect(results.first).to_not have_verification
          expect(results.resolved_selectors.find{ |s | s[:pacticipant_name] == "Bar"}.pacticipant_version_id).to eq(-1)
        end
      end
    end
  end
end
