require 'pact_broker/db/clean'

IS_MYSQL = !!DB.mysql?

module PactBroker
  module DB
    describe Clean do
      # Inner queries don't work on MySQL. Seriously, MySQL???
      describe ".call", pending: IS_MYSQL do
        let(:td) { TestDataBuilder.new }
        let(:db) { PactBroker::DB.connection }

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
            .create_deprecated_webhook_execution
            .create_verification(provider_version: "30")
            .create_consumer_version("3")
            .create_pact
            .comment("keep")
            .create_verification(provider_version: "40")
            .create_verification(provider_version: "50", number: 2)
        end

        subject { Clean.call(PactBroker::DB.connection) }

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
          expect(db[:versions].where(number: "40").count).to be 0
          expect(db[:versions].where(number: "50").count).to be 1
        end
      end
    end
  end
end
