require "pact_broker/db/data_migrations/set_interactions_counts"

module PactBroker
  module DB
    module DataMigrations
      describe SetInteractionsCounts do
        describe ".call" do
          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1")
              .create_pact(json_content: { interactions: [1, 2] }.to_json )
              .create_consumer_version("2")
              .create_pact(json_content: { interactions: [1, 2, 3] }.to_json )
              .create_provider("Bop")
              .create_pact(json_content: { messages: [1] }.to_json )
            PactBroker::Pacts::PactVersion.dataset.update(interactions_count: nil, messages_count: nil)
          end

          subject { SetInteractionsCounts.call(PactBroker::Pacts::PactVersion.db) }

          it "sets the interactions and messages counts" do
            subject
            pact_versions = PactBroker::Pacts::PactVersion.order(:id).all
            expect(pact_versions[0].interactions_count).to eq nil
            expect(pact_versions[0].messages_count).to eq nil

            expect(pact_versions[1].interactions_count).to eq 3
            expect(pact_versions[1].messages_count).to eq 0

            expect(pact_versions[2].interactions_count).to eq 0
            expect(pact_versions[2].messages_count).to eq 1
          end
        end
      end
    end
  end
end
