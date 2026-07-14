require "pact_broker/matrix/repository"

module PactBroker
  module Matrix
    describe Repository do
      describe "post-query filter ordering (limit vs latestby)" do
        # NOTE on why this test uses latestby: "cvp" rather than "cvpv":
        # MatrixRow (the model used whenever `latestby` is set) is built by joining to the
        # `latest_verification_id_for_pact_version_and_provider_version` DB view, which
        # already collapses multiple verifications for the SAME (pact_version,
        # provider_version) down to a single row *in SQL*, before Ruby ever sees the data.
        # This was confirmed empirically: constructing several verifications that share the
        # same (consumer_version, provider_version) pair produces only ONE MatrixRow row for
        # that pair regardless of whether `limit` is set - so a "cvpv" fixture can never
        # exercise apply_latestby's Ruby-level dedup at all, and can't discriminate the
        # limit/latestby ordering.
        # "cvp" (consumer_version + provider, ignoring provider_version) does NOT get this
        # SQL-level pre-dedup: each distinct provider_version verified by the consumer
        # version produces a genuinely separate MatrixRow row, and apply_latestby's Ruby
        # code is what collapses them down to the one with the highest provider_version_order.
        # That gives a real, empirically-verified case where the DB limit (applied before
        # the Ruby dedup) can truncate away an entire integration that a
        # dedup-before-limit ordering would have kept room for.
        #
        # pairA (Foo v1 / Bar) has THREE verifications against three DIFFERENT provider
        # versions (10, 11, 12), created AFTER pairB (Foo v2 / Bar v20), so all 3 of
        # pairA's rows have a newer last_action_date than pairB's single row.
        before do
          td.create_pact_with_verification("Foo", "2", "Bar", "20", true)
            .add_day
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "10", success: true, number: 1)
            .create_verification(provider_version: "11", success: false, number: 2)
            .create_verification(provider_version: "12", success: true, number: 3)
        end

        let(:selectors) do
          [
            UnresolvedSelector.new(pacticipant_name: "Foo"),
            UnresolvedSelector.new(pacticipant_name: "Bar")
          ]
        end

        subject { Repository.new.find(selectors, options) }

        context "when latestby is set but no limit (baseline)" do
          let(:options) { { latestby: "cvp" } }

          it "dedups pairA's 3 provider versions down to 1, keeping both integrations" do
            # Confirms the fixture's baseline shape: latestby collapses pairA to a single
            # row (the highest provider_version_order, pv 12), and pairB is untouched.
            expect(subject.rows.size).to eq 2
            expect(subject.rows.map(&:consumer_version_number).sort).to eq ["1", "2"]
          end
        end

        context "when limit is smaller than the row count and latestby is set" do
          let(:options) { { limit: 2, latestby: "cvp" } }

          it "applies the limit at the DB before the latestby dedup, losing pairB entirely" do
            # Pinning the ACTUAL observed behaviour: the DB limit (query.limit, applied
            # inside query_matrix BEFORE apply_latestby runs) takes the top 2 raw rows by
            # last_action_date - both from pairA's cluster (pv 12 and pv 11) - because
            # pairA's rows all sort ahead of pairB's older row. latestby then dedups those
            # 2 rows down to 1. pairB (Foo v2 / Bar v20) is lost entirely.
            #
            # If latestby ran BEFORE the limit instead, the full 4-row set would first dedup
            # to 2 rows (one per integration, as shown in the baseline context above), and a
            # limit of 2 would keep BOTH - so pairB would NOT be lost.
            expect(subject.rows.size).to eq 1
            expect(subject.rows.map(&:consumer_version_number)).to eq ["1"]
            expect(subject.rows.map(&:provider_version_number)).to eq ["12"]
          end
        end

        context "when no latestby is set" do
          let(:options) { { limit: 10 } }

          it "returns a row per pact/verification (EveryRow path)" do
            expect(subject.rows.size).to eq 4
          end
        end
      end

      describe "success filter runs after latestby" do
        # Two verifications for Foo v1 / Bar against DISTINCT provider versions (5 and 6),
        # where the HIGHER provider_version_order verification (6) FAILS and the LOWER one
        # (5) SUCCEEDS. Because the two provider versions are distinct, the SQL materialized
        # table `latest_verification_id_for_pact_version_and_provider_version` (see the NOTE
        # above) does not collapse them - BOTH rows survive to reach Ruby.
        #
        # With latestby: "cvp" (group by consumer+provider, ignoring provider_version), the
        # Ruby-level apply_latestby step is what picks a single row per integration, and it
        # is the discriminating operation here:
        #   - Real order (apply_latestby then apply_success_filter): apply_latestby picks
        #     the row with the highest provider_version_order - pv 6, which failed. Then
        #     apply_success_filter([true]) drops that row because it did not succeed.
        #   - Reversed order (apply_success_filter then apply_latestby): apply_success_filter
        #     would first drop the failing pv 6 row, leaving only the successful pv 5 row,
        #     which apply_latestby would then keep - producing 1 row instead of 0.
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "5", success: true, number: 1)
            .create_verification(provider_version: "6", success: false, number: 2)
        end

        let(:selectors) do
          [
            UnresolvedSelector.new(pacticipant_name: "Foo"),
            UnresolvedSelector.new(pacticipant_name: "Bar")
          ]
        end

        subject { Repository.new.find(selectors, options) }

        context "latestby cvp with success:[true]" do
          let(:options) { { latestby: "cvp", success: [true] } }

          it "does not resurrect the earlier successful verification once latestby has picked the (failing) highest provider_version_order row for the pair" do
            # Pinning the ACTUAL observed behaviour: apply_latestby picks the row with the
            # highest provider_version_order for the pair (pv 6, success: false).
            # apply_success_filter then runs on that single row and drops it, because
            # success:[true] excludes it. The pair is NOT resurrected via the earlier
            # successful (pv 5) verification - the result is empty.
            expect(subject.rows.size).to eq 0
          end
        end
      end
    end
  end
end
