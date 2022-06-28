require "pact_broker/webhooks/execution_configuration"

describe "migrate to pact versions (migrate 22-31)", migration: true do
  before do
    PactBroker::TestDatabase.migrate(22)
  end

  let(:now) { DateTime.new(2017, 1, 1) }
  let(:pact_updated_at) { DateTime.new(2017, 1, 2) }
  let!(:consumer) { create(:pacticipants, {name: "Consumer", created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: "Provider", created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: "1.2.3", order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: "4.5.6", order: 2, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content) { create(:pact_version_contents, {content: {some: "json"}.to_json, sha: "1234", created_at: now, updated_at: now}, :sha) }
  let!(:pact_1) { create(:pacts, {version_id: consumer_version_1[:id], provider_id: provider[:id], pact_version_content_sha: "1234", created_at: now, updated_at: pact_updated_at}) }
  let!(:pact_2) { create(:pacts, {version_id: consumer_version_2[:id], provider_id: provider[:id], pact_version_content_sha: "1234", created_at: now, updated_at: pact_updated_at}) }

  subject { PactBroker::TestDatabase.migrate }

  it "keeps the same number of pacts" do
    subject
    expect(database[:latest_pact_publications_by_consumer_versions].count).to eq 2
  end

  it "uses the old updated date for the new creation date" do
    subject
    expect(database[:latest_pact_publications_by_consumer_versions].order(:id).first[:created_at].to_datetime).to eq pact_updated_at
  end

  it "sets each revision number to 1" do
    subject
    expect(database[:latest_pact_publications_by_consumer_versions].order(:id).first[:revision_number]).to eq 1
    expect(database[:latest_pact_publications_by_consumer_versions].order(:id).last[:revision_number]).to eq 1
  end

  it "migrates the values correctly for the first pact" do

    old_all_pact = database[:all_pacts].order(:id).first
    old_all_pact.delete(:updated_at)
    old_all_pact.delete(:created_at)
    old_all_pact.delete(:created_at)
    old_all_pact[:pact_version_sha] = old_all_pact.delete(:pact_version_content_sha)
    subject
    database[:latest_pact_publications_by_consumer_versions]
    new_all_pact = database[:latest_pact_publications_by_consumer_versions].order(:id).first
    new_all_pact.delete(:created_at)
    new_all_pact.delete(:revision_number)
    new_all_pact.delete(:pact_version_id)
    expect(new_all_pact).to eq old_all_pact
  end

  it "migrates the values correctly for the second pact" do
    old_all_pact = database[:all_pacts].order(:id).last
    old_all_pact.delete(:updated_at)
    old_all_pact.delete(:created_at)
    old_all_pact[:pact_version_sha] = old_all_pact.delete(:pact_version_content_sha)
    subject
    new_all_pact = database[:latest_pact_publications_by_consumer_versions].order(:id).last
    new_all_pact.delete(:created_at)
    new_all_pact.delete(:revision_number)
    new_all_pact.delete(:pact_version_id)
    expect(new_all_pact).to eq old_all_pact
  end

  it "allows a new pact to be inserted with no duplicate ID error" do
    subject

    PactBroker::Pacts::Service.create_or_update_pact(
      {
        consumer_name: consumer[:name],
        provider_name: provider[:name],
        consumer_version_number: "1.2.3",
        json_content: load_fixture("a_consumer-a_provider.json")
      }
    )
  end
end
