require "pact_broker/db/data_migrations/set_pact_version_interaction_flags"

describe "setting the pact version interaction flags", migration: true do
  let(:now) { DateTime.new(2017, 1, 1) }
  let(:mixed_content) do
    {
      "interactions" => [
        { "type" => "Synchronous/HTTP", "request" => { "method" => "GET", "path" => "/" }, "response" => { "status" => 200 } },
        { "type" => "Asynchronous/Messages", "contents" => {} }
      ],
      "metadata" => { "pactSpecification" => { "version" => "4.0" } }
    }.to_json
  end

  def insert_pact_version(sha, content)
    consumer = create(:pacticipants, { name: "consumer-#{sha}", created_at: now, updated_at: now })
    provider = create(:pacticipants, { name: "provider-#{sha}", created_at: now, updated_at: now })
    database[:pact_versions].insert(
      consumer_id: consumer[:id], provider_id: provider[:id], sha: sha, content: content, created_at: now
    )
  end

  def applied?(version)
    database[:schema_migrations].where(Sequel.like(:filename, "#{version}_%")).any?
  end

  it "sets both flags on existing rows" do
    PactBroker::TestDatabase.migrate(20261111)
    id = insert_pact_version("abc", mixed_content)

    PactBroker::TestDatabase.migrate(20261112)

    expect(database[:pact_versions].where(id: id).first).to include(has_messages: true, has_http_interactions: true)
  end

  it "keeps the pages it committed when a later page fails, and resumes on the next run" do
    PactBroker::TestDatabase.migrate(20261111)
    page_1_ids = [insert_pact_version("a", mixed_content), insert_pact_version("b", mixed_content)]
    page_2_good_id = insert_pact_version("c", mixed_content)
    bad_id = insert_pact_version("bad", "not json")
    stub_const("PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags::BATCH_SIZE", 2)
    # The migrator wraps each migration in a transaction only where DDL is transactional (Postgres).
    allow(database).to receive(:supports_transactional_ddl?).and_return(true)

    expect { PactBroker::TestDatabase.migrate(20261112) }.to raise_error(JSON::ParserError, /pact_versions id #{bad_id}/)
    allow(database).to receive(:supports_transactional_ddl?).and_call_original
    expect(applied?(20261112)).to be false
    page_1_ids.each do |id|
      expect(database[:pact_versions].where(id: id).first).to include(has_messages: true, has_http_interactions: true)
    end
    expect(database[:pact_versions].where(id: page_2_good_id).get(:has_http_interactions)).to be_nil

    database[:pact_versions].where(id: bad_id).update(content: mixed_content)
    PactBroker::TestDatabase.migrate(20261112)

    expect(applied?(20261112)).to be true
    [page_2_good_id, bad_id].each do |id|
      expect(database[:pact_versions].where(id: id).first).to include(has_messages: true, has_http_interactions: true)
    end
  end

  it "is safe to run before the column exists" do
    PactBroker::TestDatabase.migrate(20251204)

    expect { PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags.call(database) }.not_to raise_error
  end
end
