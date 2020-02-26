require 'pact_broker/db/clean'

IS_MYSQL = !!DB.mysql?

module PactBroker
  module DB
    # Inner queries don't work on MySQL. Seriously, MySQL???
    describe Clean, pending: IS_MYSQL  do
      let(:options) { {} }
      let(:db) { PactBroker::DB.connection }

      subject { Clean.call(PactBroker::DB.connection, options) }

      describe ".call"do

        before do
          td.create_pact_with_hierarchy("Foo", "0", "Bar")
            .create_consumer_version_tag("prod")
            .create_consumer_version("1")
            .create_pact
            .create_consumer_version_tag("prod")
            .comment("keep")
            .create_verification(provider_version: "20")
            .create_consumer_version("2")
            .create_pact
            .comment("don't keep")
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_verification(provider_version: "30")
            .create_verification_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_consumer_version("3")
            .create_pact
            .comment("keep")
            .create_verification(provider_version: "40")
            .create_verification(provider_version: "40", number: 2)
            .create_verification(provider_version: "50", number: 3)
        end


        it "does not delete any rows in the head matrix" do
          head_matrix_before = db[:head_matrix].select_all
          subject
          head_matrix_after = db[:head_matrix].select_all
          expect(head_matrix_before).to eq head_matrix_after
        end

        it "deletes rows that aren't the latest or latest tagged" do
          subject
          expect(db[:matrix].where(consumer_version_number: "2").count).to eq 0
        end

        it "deletes orphan pact_versions" do
          subject
          expect(db[:pact_versions].count).to eq 2
        end

        it "deletes orphan versions" do
          subject
          expect(db[:versions].where(number: "20").count).to be 1
          expect(db[:versions].where(number: "30").count).to be 0
          expect(db[:versions].where(number: "40").count).to be 1
          expect(db[:versions].where(number: "50").count).to be 1
        end

        it "deletes overwritten verifications" do
          expect(db[:matrix].where(provider_version_number: "40").count).to eq 2
          subject
          expect(db[:matrix].where(provider_version_number: "40", verification_number: 2).count).to eq 1
        end
      end

      describe ".call with a date" do
        before do
          td.set_now(DateTime.new(2019, 1, 1))
            .create_pact_with_hierarchy
            .create_verification
        end
        let(:options) { { date: date } }

        context "when the data is older than the given date" do
          let(:date) { DateTime.new(2019, 1, 2) }
          let(:expected_report) do
            {
              kept: { pact_publications: 0, verification_results: 0 },
              deleted: { pact_publications: 1, verification_results: 1 }
            }
          end

          it "is deleted" do
            subject
            expect(db[:head_matrix].count).to be 0
          end

          it "returns a report" do
            expect(subject).to include(expected_report)
          end
        end

        context "when the data is not older than the given date" do
          let(:date) { DateTime.new(2019, 1, 1) }
          let(:expected_report) do
            {
              kept: { pact_publications: 1, verification_results: 1 },
              deleted: { pact_publications: 0, verification_results: 0 }
            }
          end

          it "is not deleted" do
            subject
            expect(db[:head_matrix].count).to be 1
            expect(db[:pact_publications].count).to be 1
            expect(db[:verifications].count).to be 1
          end

          it "returns a report" do
            expect(subject).to include(expected_report)
          end
        end
      end
    end
  end
end
