require 'pact_broker/db/data_migrations/migrate_pact_version_provider_tag_successful_verifications'

module PactBroker
  module DB
    module DataMigrations
      describe MigratePactVersionProviderTagSuccessfulVerifications do
        describe ".call" do
          before do
            td.set_now(Date.new(2020, 2, 1))
              .publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1")
              .set_now(Date.new(2021, 2, 1))
              .create_verification(provider_version: "2", tag_names: ["feat/x"], wip: true, success: false)
              .publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "2")
              .set_now(Date.new(2022, 2, 1))
              .create_verification(provider_version: "3", tag_names: ["feat/x"], wip: true, success: true)
              .set_now(Date.new(2023, 2, 1))
              .create_verification(provider_version: "4", tag_names: ["feat/x"], wip: true, success: true, number: 2)
              .set_now(Date.new(2024, 2, 1))
              .create_verification(provider_version: "5", tag_names: ["feat/x"], wip: false, success: true, number: 3)
              .set_now(Date.new(2025, 2, 1))
              .create_verification(provider_version: "6", tag_names: ["feat/x"], wip: false, success: true, number: 4)

              Sequel::Model.db[:pact_version_provider_tag_successful_verifications].delete
          end

          subject do
            MigratePactVersionProviderTagSuccessfulVerifications.call(Sequel::Model.db)
            MigratePactVersionProviderTagSuccessfulVerifications.call(Sequel::Model.db)
          end

          let(:first_verification) { Sequel::Model.db[:verifications].where(provider_version_id: Sequel::Model.db[:versions].select(:id).where(number: "3")).first }
          let(:last_verification) { Sequel::Model.db[:verifications].where(provider_version_id: Sequel::Model.db[:versions].select(:id).where(number: "5")).first }

          it "uses the date of the first verification for each wip status (true/false) for the row" do
            expect { subject }.to change { Sequel::Model.db[:pact_version_provider_tag_successful_verifications].count }.by(2)

            first_row = Sequel::Model.db[:pact_version_provider_tag_successful_verifications].order(:id).first

            expect(first_row[:execution_date].to_s).to include "2022"
            expect(first_row[:verification_id]).to eq first_verification[:id]

            last_row = Sequel::Model.db[:pact_version_provider_tag_successful_verifications].order(:id).last

            expect(last_row[:execution_date].to_s).to include "2024"
            expect(last_row[:verification_id]).to eq last_verification[:id]
          end
        end
      end
    end
  end
end
