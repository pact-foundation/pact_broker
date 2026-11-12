describe "making has_http_interactions NOT NULL", migration: true do
  let(:now) { DateTime.new(2017, 1, 1) }
  let(:http) { { "type" => "Synchronous/HTTP", "request" => { "method" => "GET", "path" => "/" }, "response" => { "status" => 200 } } }
  let(:message) { { "type" => "Asynchronous/Messages", "contents" => {} } }

  def allow_null?
    database.schema(:pact_versions, reload: true).find { |column| column.first == :has_http_interactions }.last[:allow_null]
  end

  def applied?(version)
    database[:schema_migrations].where(Sequel.like(:filename, "#{version}_%")).any?
  end

  def pact_version_row(sha, interactions)
    consumer = create(:pacticipants, { name: "consumer-#{sha}", created_at: now, updated_at: now })
    provider = create(:pacticipants, { name: "provider-#{sha}", created_at: now, updated_at: now })
    content = { "interactions" => interactions, "metadata" => { "pactSpecification" => { "version" => "4.0" } } }.to_json
    { consumer_id: consumer[:id], provider_id: provider[:id], sha: sha, content: content, created_at: now }
  end

  def insert_pact_version(sha, interactions)
    database[:pact_versions].insert(pact_version_row(sha, interactions).merge(has_http_interactions: nil))
  end

  def has_http_interactions(id)
    database[:pact_versions].where(id: id).get(:has_http_interactions)
  end

  it "fills rows that are still NULL and then forbids NULL" do
    PactBroker::TestDatabase.migrate(20261112)
    http_id = insert_pact_version("http", [http])
    mixed_id = insert_pact_version("mixed", [http, message])
    message_id = insert_pact_version("message", [message])
    empty_id = insert_pact_version("empty", [])
    expect(allow_null?).to be true

    PactBroker::TestDatabase.migrate(20261113)

    expect(has_http_interactions(http_id)).to be true
    expect(has_http_interactions(mixed_id)).to be true
    expect(has_http_interactions(message_id)).to be false
    expect(has_http_interactions(empty_id)).to be false
    expect(database[:pact_versions].where(id: message_id).get(:has_messages)).to be true
    expect(allow_null?).to be false
  end

  it "keeps a value that is already set" do
    PactBroker::TestDatabase.migrate(20261112)
    id = database[:pact_versions].insert(pact_version_row("set", [message]).merge(has_http_interactions: true))

    PactBroker::TestDatabase.migrate(20261113)

    expect(has_http_interactions(id)).to be true
  end

  it "rejects a row without has_http_interactions" do
    PactBroker::TestDatabase.migrate(20261113)

    expect { database[:pact_versions].insert(pact_version_row("nil", [http]).merge(has_http_interactions: nil)) }
      .to raise_error(Sequel::NotNullConstraintViolation)
    expect { database[:pact_versions].insert(pact_version_row("omitted", [http])) }
      .to raise_error(Sequel::NotNullConstraintViolation)
  end

  context "when a row's content cannot be parsed" do
    let!(:bad_id) do
      PactBroker::TestDatabase.migrate(20261112)
      insert_pact_version("bad", [http]).tap do |id|
        database[:pact_versions].where(id: id).update(content: "not json")
      end
    end

    # The after-each hook migrates to the latest schema, which runs the fill again.
    after { database[:pact_versions].where(id: bad_id).update(content: { "interactions" => [http] }.to_json) }

    it "fails with the row id and leaves the column nullable and the migration pending" do
      expect { PactBroker::TestDatabase.migrate(20261113) }.to raise_error(JSON::ParserError, /pact_versions id #{bad_id}/)

      expect(allow_null?).to be true
      expect(applied?(20261113)).to be false
    end
  end

  it "allows NULL again when rolled back" do
    PactBroker::TestDatabase.migrate(20261113)

    PactBroker::TestDatabase.migrate(20261111)

    expect(allow_null?).to be true
  end
end
