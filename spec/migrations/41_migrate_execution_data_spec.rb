require 'tasks/database'

describe 'creating triggered webhooks from webhook executions (migrate 36-41)', no_db_clean: :true do

  def create table_name, params, id_column_name = :id
    database[table_name].insert(params);
    database[table_name].order(id_column_name).last
  end

  let(:database) { DB.connection_for_env 'test' }

  before do
    PactBroker::Database.drop_objects
    PactBroker::Database.migrate(36)
  end

  let(:before_now) { DateTime.new(2016, 1, 1) }
  let(:now) { DateTime.new(2018, 2, 2) }
  let(:consumer) { create(:pacticipants, {name: 'Consumer', created_at: now, updated_at: now}) }
  let(:provider) { create(:pacticipants, {name: 'Provider', created_at: now, updated_at: now}) }
  let(:consumer_version) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let(:pact_version) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '1234', consumer_id: consumer[:id], provider_id: provider[:id], created_at: now}) }
  let(:pact_publication) do
    create(:pact_publications, {
      consumer_version_id: consumer_version[:id],
      provider_id: provider[:id],
      revision_number: 1,
      pact_version_id: pact_version[:id],
      created_at: (now - 1)
    })
  end

  let(:pact_publication_2) do
    create(:pact_publications, {
      consumer_version_id: consumer_version[:id],
      provider_id: provider[:id],
      revision_number: 2,
      pact_version_id: pact_version[:id],
      created_at: now
    })
  end
  let(:pact_publication_3) do
    create(:pact_publications, {
      consumer_version_id: consumer_version[:id],
      provider_id: provider[:id],
      revision_number: 3,
      pact_version_id: pact_version[:id],
      created_at: (now + 1)
    })
  end
  let(:webhook) do
    create(:webhooks, {
      uuid: '1234',
      method: 'GET',
      url: 'http://www.example.org',
      consumer_id: consumer[:id],
      provider_id: provider[:id],
      is_json_request_body: false,
      created_at: now
    })
  end
  let(:webhook_execution) do
    create(:webhook_executions, {
      webhook_id: webhook[:id],
      pact_publication_id: pact_publication[:id],
      consumer_id: consumer[:id],
      provider_id: provider[:id],
      success: true,
      logs: 'logs',
      created_at: now
    })
  end

  let(:do_migration) do
    PactBroker::Database.migrate(41)
  end

  context "when a pact_publication can be found" do
    before do
      pact_publication
      pact_publication_2
      pact_publication_3
      webhook_execution
    end

    it "creates a triggered webhook for each webhook execution" do
      do_migration
      expect(database[:triggered_webhooks].count).to eq 1
      expect(database[:triggered_webhooks].first[:webhook_id]).to eq webhook[:id]
      expect(database[:triggered_webhooks].first[:webhook_uuid]).to eq '1234'
      expect(database[:triggered_webhooks].first[:consumer_id]).to eq consumer[:id]
      expect(database[:triggered_webhooks].first[:provider_id]).to eq provider[:id]
      expect(database[:triggered_webhooks].first[:pact_publication_id]).to eq pact_publication_2[:id]
      expect(database[:triggered_webhooks].first[:status]).to eq 'success'
      expect(database[:triggered_webhooks].first[:created_at]).to eq webhook[:created_at]
      expect(database[:triggered_webhooks].first[:updated_at]).to eq webhook[:created_at]
    end

    context "migrating backwards" do
      it "deletes the triggered_webhooks again" do
        do_migration
        PactBroker::Database.migrate(40)
        expect(database[:triggered_webhooks].count).to eq 0
      end
    end
  end

  context "when a pact_publication cannot be found" do
    it "does not insert a triggered webhook" do
      do_migration
      expect(database[:triggered_webhooks].count).to eq 0
    end
  end

  after do
    PactBroker::Database.migrate
    PactBroker::Database.truncate
  end
end
