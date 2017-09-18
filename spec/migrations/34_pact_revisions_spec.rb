describe 'using pact publications (migrate 31-32)', migration: true do
  before do
    PactBroker::Database.migrate(33)
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
  let!(:consumer_version_3) { create(:versions, {number: '4.5.6', order: 1, pacticipant_id: consumer_2[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content_2) { create(:pact_versions, {content: {some: 'json'}.to_json, sha: '4567', consumer_id: consumer_2[:id], provider_id: provider_2[:id], created_at: now}) }
  let!(:pact_version_3_revision_1) { create(:pact_publications, {consumer_version_id: consumer_version_3[:id], provider_id: provider_2[:id], pact_version_id: pact_version_content_2[:id], created_at: now, revision_number: 1}) }

  subject do
    PactBroker::Database.migrate(34)
    database.schema(:latest_pact_publication_revision_numbers, reload: true)
  end

  describe "all_pact_publications" do
    it "has a row for every revision" do
      subject
      expect(database[:all_pact_publications].count).to eq 4
    end
  end

  describe "latest_pact_publications_by_consumer_versions" do
    it "has a row for every pact" do
      subject
      expect(database[:latest_pact_publications_by_consumer_versions].count).to eq 3
    end
  end

  describe "latest_pact_publication_revision_numbers" do
    it "contains the latest revision number for each consumer version" do
      subject
      expect(database[:latest_pact_publication_revision_numbers].where(
        provider_id: provider_1[:id], consumer_id: consumer_1[:id],
        consumer_version_order: 1, latest_revision_number: 1
        ).count
      ).to eq 1
      expect(database[:latest_pact_publication_revision_numbers].where(
        provider_id: provider_1[:id], consumer_id: consumer_1[:id],
        consumer_version_order: 2, latest_revision_number: 2
        ).count
      ).to eq 1
      expect(database[:latest_pact_publication_revision_numbers].where(
        provider_id: provider_2[:id], consumer_id: consumer_2[:id],
        consumer_version_order: 1, latest_revision_number: 1
        ).count
      ).to eq 1
    end
  end

  describe "latest_pact_consumer_version_orders" do
    it "contains the latest consumer version for each consumer/provider pair" do
      subject
      expect(database[:latest_pact_consumer_version_orders].count).to eq 2
      expect(database[:latest_pact_consumer_version_orders].where(
        provider_id: provider_1[:id], consumer_id: consumer_1[:id],
        latest_consumer_version_order: 2
        ).count
      ).to eq 1

    end
  end

  describe "latest_pact_publications" do
    it "only contains the latest revision of the pact for the latest consumer version" do
      subject
      expect(database[:latest_pact_publications].count).to eq 2
      expect(database[:latest_pact_publications].where(provider_id: provider_1[:id], consumer_id: consumer_1[:id]).count).to eq 1
    end
  end
end
