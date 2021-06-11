describe "migrate to pact versions (migrate 22-24)", migration: true do
  before do
    PactBroker::Database.migrate(22)
  end

  let(:now) { DateTime.new(2017, 1, 1) }
  let(:pact_updated_at) { DateTime.new(2017, 1, 2) }
  let!(:consumer) { create(:pacticipants, {name: "Consumer", created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: "Provider", created_at: now, updated_at: now}) }
  let!(:consumer_version) { create(:versions, {number: "1.2.3", order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content) { create(:pact_version_contents, {content: {some: "json"}.to_json, sha: "1234", created_at: now, updated_at: now}, :sha) }
  let!(:pact_1) { create(:pacts, {version_id: consumer_version[:id], provider_id: provider[:id], pact_version_content_sha: "1234", created_at: now, updated_at: pact_updated_at}) }

  let!(:pact_version_content_orphan) { create(:pact_version_contents, {content: {some: "json"}.to_json, sha: "4567", created_at: now, updated_at: now}, :sha) }

  subject { PactBroker::Database.migrate(34) }

  it "deletes orphan pact_versions" do
    subject
    expect(database[:pact_versions].count).to eq 1
  end
end
