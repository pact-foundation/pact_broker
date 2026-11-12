describe "adding has_http_interactions to pact_versions", migration: true do
  let(:now) { DateTime.new(2017, 1, 1) }

  def insert_pact_version(sha)
    consumer = create(:pacticipants, { name: "consumer-#{sha}", created_at: now, updated_at: now })
    provider = create(:pacticipants, { name: "provider-#{sha}", created_at: now, updated_at: now })
    database[:pact_versions].insert(
      consumer_id: consumer[:id], provider_id: provider[:id], sha: sha, content: "{}", created_at: now
    )
  end

  def column_names
    database.schema(:pact_versions, reload: true).map(&:first)
  end

  before do
    PactBroker::TestDatabase.migrate(20261111)
  end

  it "adds a nullable column with no default" do
    column = database.schema(:pact_versions).to_h.fetch(:has_http_interactions)

    expect(column[:type]).to eq(:boolean)
    expect(column[:allow_null]).to be true
    expect(column[:ruby_default]).to be_nil
  end

  it "reads back nil for a row inserted without the column" do
    pact_version_id = insert_pact_version("abc")

    expect(database[:pact_versions].where(id: pact_version_id).first).to include(has_http_interactions: nil)
  end

  it "leaves has_http_interactions nil on rows that existed before the migration" do
    PactBroker::TestDatabase.migrate(20260217)
    pact_version_id = insert_pact_version("existing")

    PactBroker::TestDatabase.migrate(20261111)

    expect(database[:pact_versions].where(id: pact_version_id).first).to include(has_http_interactions: nil)
  end

  it "drops the column and keeps existing rows when rolled back" do
    pact_version_id = insert_pact_version("existing")
    expect(column_names).to include(:has_http_interactions)

    PactBroker::TestDatabase.migrate(20260217)

    expect(column_names).not_to include(:has_http_interactions)
    expect(database[:pact_versions].where(id: pact_version_id).count).to eq 1
  end
end
