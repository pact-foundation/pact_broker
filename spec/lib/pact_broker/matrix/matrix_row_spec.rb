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
      end
    end
  end
end
