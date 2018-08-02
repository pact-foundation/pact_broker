require 'pact_broker/db/data_migrations/set_consumer_ids_for_pact_publications'

module PactBroker
  module DB
    module DataMigrations
      describe SetConsumerIdsForPactPublications, migration: true do
        describe ".call" do
          before do
            PactBroker::Database.migrate(20180615)
          end

          let(:now) { DateTime.new(2018, 2, 2) }
          let!(:consumer_other) { create(:pacticipants, {name: 'Other consumer', created_at: now, updated_at: now}) }
          let!(:consumer) { create(:pacticipants, {name: 'Consumer', created_at: now, updated_at: now}) }
          let!(:provider) { create(:pacticipants, {name: 'Provider', created_at: now, updated_at: now}) }
          let!(:consumer_version) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
          let!(:pact_version) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '1234', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
          let!(:pact_publication) do
            create(:pact_publications, {
              consumer_version_id: consumer_version[:id],
              provider_id: provider[:id],
              revision_number: 1,
              pact_version_id: pact_version[:id],
              created_at: (now - 1)
            })
          end

          subject { SetConsumerIdsForPactPublications.call(database) }

          it "sets the consumer_id" do
            expect(database[:pact_publications].first[:consumer_id]).to be nil
            subject
            expect(database[:pact_publications].first[:consumer_id]).to_not be nil
            expect(database[:pact_publications].first[:consumer_id]).to eq consumer[:id]
          end
        end
      end
    end
  end
end
