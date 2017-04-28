require 'tasks/database'

describe 'using pact publications (migrate 31-32)', no_db_clean: :true do

  def create table_name, params, id_column_name = :id
    database[table_name].insert(params);
    database[table_name].order(id_column_name).last
  end

  let(:database) { DB.connection_for_env 'test' }

  before do
    PactBroker::Database.drop_objects
    PactBroker::Database.migrate(34)
  end

  let(:now) { DateTime.new(2017, 1, 1) }
  let!(:consumer_1) { create(:pacticipants, {name: 'Consumer 1', created_at: now, updated_at: now}) }
  let!(:provider_1) { create(:pacticipants, {name: 'Provider 1', created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer_1[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: '4.5.6', order: 2, pacticipant_id: consumer_1[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content_1) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '1234', consumer_id: consumer_1[:id], provider_id: provider_1[:id], created_at: now}) }
  let!(:pact_version_1_revision_1) { create(:pact_publications, {consumer_version_id: consumer_version_1[:id], provider_id: provider_1[:id], pact_version_id: pact_version_content_1[:id], created_at: now, revision_number: 1}) }
  let!(:pact_version_2_revision_1) { create(:pact_publications, {consumer_version_id: consumer_version_2[:id], provider_id: provider_1[:id], pact_version_id: pact_version_content_1[:id], created_at: now, revision_number: 1}) }
  let!(:pact_version_2_revision_2) { create(:pact_publications, {consumer_version_id: consumer_version_2[:id], provider_id: provider_1[:id], pact_version_id: pact_version_content_1[:id], created_at: now, revision_number: 2}) }

  let!(:consumer_2) { create(:pacticipants, {name: 'Consumer 2', created_at: now, updated_at: now}) }
  let!(:provider_2) { create(:pacticipants, {name: 'Provider 2', created_at: now, updated_at: now}) }
  let!(:consumer_version_3) { create(:versions, {number: '7.8.9', order: 1, pacticipant_id: consumer_2[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content_2) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '4567', consumer_id: consumer_2[:id], provider_id: provider_2[:id], created_at: now}) }
  let!(:pact_version_3_revision_1) { create(:pact_publications, {consumer_version_id: consumer_version_3[:id], provider_id: provider_2[:id], pact_version_id: pact_version_content_2[:id], created_at: now, revision_number: 1}) }

  # Consumer 1/Provider 1 version 1.2.3
  let!(:tag_1) { create(:tags, {version_id: consumer_version_1[:id], name: 'master', created_at: now, updated_at: now}, :created_at) } #not included

  # Consumer 1/Provider 1 version 4.5.6
  let!(:tag_2) { create(:tags, {version_id: consumer_version_2[:id], name: 'master', created_at: now, updated_at: now}, :created_at) } #included
  let!(:tag_3) { create(:tags, {version_id: consumer_version_2[:id], name: 'prod', created_at: now, updated_at: now}, :created_at) } #included

  # Consumer 2/Provider 2 version 7.8.9
  let!(:tag_4) { create(:tags, {version_id: consumer_version_3[:id], name: 'prod', created_at: now, updated_at: now}, :created_at) } #included

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

  describe "latest_tagged_pact_publications" do
    it "only contains the latest revision of the pact for the latest consumer version with each tag" do
      expect(database[:latest_tagged_pact_publications].where(
        provider_name: 'Provider 1', consumer_name: 'Consumer 1',
        consumer_version_number: '4.5.6', revision_number: 2, tag_name: 'prod'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pact_publications].where(
        provider_name: 'Provider 1', consumer_name: 'Consumer 1',
        consumer_version_number: '4.5.6', revision_number: 2, tag_name: 'master'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pact_publications].where(
        provider_name: 'Provider 2', consumer_name: 'Consumer 2',
        consumer_version_number: '7.8.9', revision_number: 1,  tag_name: 'prod'
        ).count
      ).to eq 1

      expect(database[:latest_tagged_pact_publications].count).to eq 3
    end

    it "has a created_at column" do
      expect(database[:latest_tagged_pact_publications].order(:id).first).to have_key(:created_at)
    end

    it "doesn't have an updated_at column" do
      expect(database[:latest_tagged_pact_publications].order(:id).first).to_not have_key(:updated_at)
    end
  end

  after do
    PactBroker::Database.migrate
    PactBroker::Database.truncate
  end
end
