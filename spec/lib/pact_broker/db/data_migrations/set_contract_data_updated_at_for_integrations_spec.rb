require "pact_broker/db/data_migrations/set_contract_data_updated_at_for_integrations"
require "timecop"
require "tzinfo"

module PactBroker
  module DB
    module DataMigrations
      describe SetContractDataUpdatedAtForIntegrations do
        before do
          td.clear_now # use timecop instead of the TestDataBuilder @now

          Timecop.freeze(day_1) do
            td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1")
          end

          Timecop.freeze(day_2) do
            td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "2")
          end

          Timecop.freeze(day_3) do
            td.create_verification(provider_version: "2")
          end

          Timecop.freeze(day_4) do
            td.publish_pact(consumer_name: "Cat", provider_name: "Dog", consumer_version_number: "2")
          end

          db[:integrations].update(contract_data_updated_at: nil)
        end

        let(:day_1) { td.in_utc{ DateTime.new(2023, 6, 11) } }
        let(:day_2) { td.in_utc{ DateTime.new(2023, 6, 12) } }
        let(:day_3) { td.in_utc{ DateTime.new(2023, 6, 13) } }
        let(:day_4) { td.in_utc{ DateTime.new(2023, 6, 14) } }

        let(:db) { PactBroker::Domain::Version.db }

        subject { SetContractDataUpdatedAtForIntegrations.call(db) }

        it "sets the contract_data_updated_at to the latest of the pact publication and verification publication dates for that integration" do
          subject
          integrations = db[:integrations].order(:id)
          expect(integrations.first[:contract_data_updated_at]).to eq day_3
          expect(integrations.last[:contract_data_updated_at]).to eq day_4
        end
      end
    end
  end
end
