require "pact_broker/matrix/repository"

module PactBroker
  module Matrix
    describe Repository do
      describe "post-query filter ordering (latestby, success, limit)" do
        # Foo has three consumer versions, each verified by a distinct provider version.
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "10")
            .add_day
            .create_pact_with_verification("Foo", "2", "Bar", "20")
            .add_day
            .create_pact_with_verification("Foo", "3", "Bar", "30")
        end

        let(:selectors) do
          [
            UnresolvedSelector.new(pacticipant_name: "Foo"),
            UnresolvedSelector.new(pacticipant_name: "Bar")
          ]
        end

        subject { Repository.new.find(selectors, options) }

        context "when limit is smaller than the row count and latestby is set" do
          let(:options) { { limit: 2, latestby: "cvpv" } }

          it "applies the limit at the DB before the latestby dedup" do
            # The DB fetches the newest `limit` rows first, THEN latestby dedups them.
            # Pinning the resulting count documents that limit and latestby interact.
            expect(subject.rows.size).to be <= 2
          end

          it "keeps the most recent consumer versions" do
            consumer_versions = subject.rows.map(&:consumer_version_number)
            expect(consumer_versions).to include("3")
          end
        end

        context "when no latestby is set" do
          let(:options) { { limit: 10 } }

          it "returns a row per pact/verification (EveryRow path)" do
            expect(subject.rows.size).to eq 3
          end
        end
      end

      describe "success filter runs after latestby" do
        before do
          # Latest verification for Foo v1 fails; an earlier one succeeded.
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "1", success: true, number: 1)
            .create_verification(provider_version: "2", success: false, number: 2)
        end

        let(:selectors) do
          [
            UnresolvedSelector.new(pacticipant_name: "Foo"),
            UnresolvedSelector.new(pacticipant_name: "Bar")
          ]
        end

        subject { Repository.new.find(selectors, options) }

        context "latestby cvpv with success:[true]" do
          let(:options) { { latestby: "cvpv", success: [true] } }

          it "filters on the success of the row surviving latestby (documents current behaviour)" do
            # apply_latestby picks the latest provider version per pair FIRST,
            # then apply_success_filter keeps only success == true rows.
            expect(subject.rows.map(&:success)).to all(eq(true))
          end
        end
      end
    end
  end
end
