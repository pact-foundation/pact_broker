require 'tasks/database'

describe 'using pact revisions (migrate 31-32)', no_db_clean: :true do

  def create table_name, params, id_column_name = :id
    database[table_name].insert(params);
    database[table_name].order(id_column_name).last
  end

  def new_connection
    DB.connection_for_env 'test'
  end

  let(:database) { new_connection }

  before do
    PactBroker::Database.delete_database_file
    PactBroker::Database.ensure_database_dir_exists
    database = new_connection
    PactBroker::Database.migrate(32)
  end

  let(:now) { DateTime.new }
  let(:pact_updated_at) { DateTime.new + 1}
  let!(:consumer_1) { create(:pacticipants, {name: 'Consumer 1', created_at: now, updated_at: now}) }
  let!(:provider_1) { create(:pacticipants, {name: 'Provider 1', created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer_1[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: '4.5.6', order: 2, pacticipant_id: consumer_1[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content_1) { create(:pact_version_contents, {content: {some: 'json'}.to_json, sha: '1234', created_at: now}) }
  let!(:pact_version_1_revision_1) { create(:pact_revisions, {consumer_version_id: consumer_version_1[:id], provider_id: provider_1[:id], pact_version_content_id: pact_version_content_1[:id], created_at: now, revision_number: 1}) }
  let!(:pact_version_2_revision_1) { create(:pact_revisions, {consumer_version_id: consumer_version_2[:id], provider_id: provider_1[:id], pact_version_content_id: pact_version_content_1[:id], created_at: now, revision_number: 1}) }
  let!(:pact_version_2_revision_2) { create(:pact_revisions, {consumer_version_id: consumer_version_2[:id], provider_id: provider_1[:id], pact_version_content_id: pact_version_content_1[:id], created_at: now, revision_number: 2}) }

  let!(:consumer_2) { create(:pacticipants, {name: 'Consumer 2', created_at: now, updated_at: now}) }
  let!(:provider_2) { create(:pacticipants, {name: 'Provider 2', created_at: now, updated_at: now}) }
  let!(:consumer_version_3) { create(:versions, {number: '7.8.9', order: 1, pacticipant_id: consumer_2[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content_2) { create(:pact_version_contents, {content: {some: 'json'}.to_json, sha: '4567', created_at: now}) }
  let!(:pact_version_3_revision_1) { create(:pact_revisions, {consumer_version_id: consumer_version_3[:id], provider_id: provider_2[:id], pact_version_content_id: pact_version_content_2[:id], created_at: now, revision_number: 1}) }

  # Consumer 1/Provider 1 version 1.2.3
  let!(:tag_1) { create(:tags, {version_id: consumer_version_1[:id], name: 'master', created_at: now, updated_at: now}, :created_at) } #not included

  # Consumer 1/Provider 1 version 4.5.6
  let!(:tag_2) { create(:tags, {version_id: consumer_version_2[:id], name: 'master', created_at: now, updated_at: now}, :created_at) } #included
  let!(:tag_3) { create(:tags, {version_id: consumer_version_2[:id], name: 'prod', created_at: now, updated_at: now}, :created_at) } #included

  # Consumer 2/Provider 2 version 7.8.9
  let!(:tag_4) { create(:tags, {version_id: consumer_version_3[:id], name: 'prod', created_at: now, updated_at: now}, :created_at) } #included

  let(:do_migration) do
    PactBroker::Database.migrate(33)
    database.schema(:latest_tagged_pacts, reload: true)
  end

  describe "latest_tagged_pact_consumer_version_orders" do
    it "contains a row with the latest consumer version order for each consumer/provider/tag combination" do
      expect(database[:latest_tagged_pact_consumer_version_orders].where(
        provider_id: provider_1[:id], consumer_id: consumer_1[:id], tag_name: 'master'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pact_consumer_version_orders].where(
        provider_id: provider_1[:id], consumer_id: consumer_1[:id], tag_name: 'prod'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pact_consumer_version_orders].where(
        provider_id: provider_2[:id], consumer_id: consumer_2[:id], tag_name: 'prod'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pact_consumer_version_orders].count).to eq 3
    end
  end

  describe "latest_tagged_pacts" do
    it "only contains the latest revision of the pact for the latest consumer version with each tag" do
      do_migration

      expect(database[:latest_tagged_pacts].where(
        provider_name: 'Provider 1', consumer_name: 'Consumer 1',
        consumer_version_number: '4.5.6', revision_number: 2, tag_name: 'prod'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pacts].where(
        provider_name: 'Provider 1', consumer_name: 'Consumer 1',
        consumer_version_number: '4.5.6', revision_number: 2, tag_name: 'master'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pacts].where(
        provider_name: 'Provider 2', consumer_name: 'Consumer 2',
        consumer_version_number: '7.8.9', revision_number: 1,  tag_name: 'prod'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pacts].count).to eq 3
    end

  end

  after do
    PactBroker::Database.delete_database_file
    PactBroker::Database.ensure_database_dir_exists
    database = new_connection
    PactBroker::Database.migrate
  end
end
