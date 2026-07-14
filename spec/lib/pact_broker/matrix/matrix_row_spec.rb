require "pact_broker/matrix/matrix_row"
require "pact_broker/matrix/resolved_selector"

module PactBroker
  module Matrix
    describe MatrixRow do
      describe "the interface" do
        before do
          td.create_pact_with_hierarchy("A", "1", "B")
            .create_verification(provider_version: "1", success: false)
            .create_verification(provider_version: "1", number: 2, success: true)
            .create_verification(provider_version: "2", number: 3, success: true)
            .create_provider("C")
            .create_pact
            .create_verification(provider_version: "1")
            .create_consumer_version("2")
            .create_pact
            .create_verification(provider_version: "3")
            .use_provider("B")
            .create_pact
        end

        it "behaves like a Row, except quicker" do
          a_id = MatrixRow.db[:pacticipants].where(name: "A").select(:id).single_record[:id]
          rows = MatrixRow.default_scope.where(consumer_id: a_id).eager(:consumer).eager(:verification).all
          expect(rows.first.consumer).to be rows.last.consumer
          expect(rows.first.verification).to_not be nil
          expect(rows.first.consumer_name).to_not be nil
          expect(rows.first.provider_name).to_not be nil
        end

      end

      describe "order_by_last_action_date" do
        subject { MatrixRow.default_scope.order_by_last_action_date }

        context "when there are two pacts verified at the same time" do
          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("10")
              .create_pact(created_at: day_1)
              .create_verification(provider_version: "2", created_at: day_3)
              .create_consumer_version("3")
              .create_pact(created_at: day_2)
              .create_verification(provider_version: "2", created_at: day_3)
          end

          let(:day_1) { DateTime.now + 1  }
          let(:day_2) { DateTime.now + 2  }
          let(:day_3) { DateTime.now + 3  }

          it "orders by the pact publication id desc" do
            expect(subject.first.last_action_date).to eq subject.last.last_action_date
            expect(subject.first.consumer_version_number).to eq "3"
            expect(subject.last.consumer_version_number).to eq "10"
          end
        end

        context "when a pact has been published after a pact has been verified" do
          before do
            td.create_pact_with_verification("Foo", "1", "Bar", "2")
              .create_pact_with_hierarchy("Foo", "2", "Bar")
          end

          it "puts the unverified pact before the verification" do
            expect(subject.first.consumer_version_number).to eq "2"
            expect(subject.last.consumer_version_number).to eq "1"
          end
        end

        context "when two different pacts share the same last action date (pact_order tie-break)" do
          before do
            # Two DIFFERENT pacts published and verified on the same simulated day, so
            # last_action_date ties and the query falls through to ordering by pact_order desc.
            # pact_order is the pact_publication_id, which is unique per pact, so it always
            # disambiguates two different pacts before the query would need to reach the
            # further verification_id desc tie-break. See the "verification_id tie-break"
            # context below for a fixture where pact_order also ties, forcing the ordering
            # through to verification_id.
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "10", created_at: day_1)
              .create_pact_with_hierarchy("Foo", "2", "Baz")
              .create_verification(provider_version: "20", created_at: day_1)
          end

          let(:day_1) { DateTime.now + 1 }

          it "orders the most recently created pact first (documents current pact_order tie-break)" do
            expect(subject.first.last_action_date).to eq subject.last.last_action_date
            expect(subject.first.consumer_version_number).to eq "2"
            expect(subject.last.consumer_version_number).to eq "1"
          end
        end

        context "when the same pact is verified by two provider versions on the same last action date (verification_id tie-break)" do
          before do
            # ONE pact (one pact_publication_id) verified by TWO provider versions, both created
            # at the same simulated instant. Because it's the same pact, both rows share the same
            # pact_order (pact_publication_id), so the first tie-break (pact_order) also ties.
            # Because both provider versions share the same created_at, and last_action_date is
            # the max of consumer_version_created_at/provider_version_created_at for a single
            # shared consumer version, both rows' last_action_date ties too. This forces the
            # ordering through to the third tie-break, verification_id desc.
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "10", created_at: day_1)
              .create_verification(provider_version: "20", number: 2, created_at: day_1)
          end

          let(:day_1) { DateTime.now + 1 }

          it "orders the most recently created verification first (documents current verification_id tie-break)" do
            expect(subject.first.last_action_date).to eq subject.last.last_action_date
            expect(subject.first.values[:pact_order]).to eq subject.last.values[:pact_order]
            expect(subject.first.consumer_version_number).to eq subject.last.consumer_version_number
            expect(subject.first.provider_version_number).to eq "20"
            expect(subject.last.provider_version_number).to eq "10"
          end
        end

        context "when the row comes from the database" do
          before do
            td.create_pact_with_verification("Foo", "1", "Bar", "2")
          end

          it "returns a real date/time object, not a String, for last_action_date" do
            expect(subject.first.last_action_date).to be_a(Date).or be_a(Time).or be_a(DateTime)
          end
        end
      end

      describe "#verification_id" do
        context "when the verification table has not been joined" do
          subject { MatrixRow.new }

          it "raises an error" do
            expect { subject.verification_id }.to raise_error("Required table not joined")
          end
        end
      end

      describe "matching_one_selector_for_either_consumer_or_provider" do
        context "when the number of selectors provided is not 1" do
          it "raises an ArgumentError" do
            expect { MatrixRow.default_scope.send(:matching_one_selector_for_either_consumer_or_provider, [], limit: 1) }.to raise_error(ArgumentError, "Expected one selector to be provided, but received 0:  []")
          end
        end
      end
    end
  end
end
