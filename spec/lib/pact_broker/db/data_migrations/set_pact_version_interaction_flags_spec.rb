require "pact_broker/db/data_migrations/set_pact_version_interaction_flags"

RSpec.describe PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags, migration: true do
  # Migration specs start from an empty database, so each example picks its schema version first.
  before { PactBroker::TestDatabase.migrate(20261112) }

  def pact_json(version:, interactions: [], messages: nil)
    content = { "consumer" => { "name" => "c" }, "provider" => { "name" => "p" }, "interactions" => interactions }
    content["messages"] = messages if messages
    content["metadata"] = { "pactSpecification" => { "version" => version } } if version
    content.to_json
  end

  let(:http) { { "type" => "Synchronous/HTTP", "description" => "h", "request" => { "method" => "GET", "path" => "/" }, "response" => { "status" => 200 } } }
  let(:message) { { "type" => "Asynchronous/Messages", "description" => "m", "contents" => {} } }
  let(:untyped_http) { { "description" => "h", "request" => { "method" => "GET", "path" => "/" }, "response" => { "status" => 200 } } }
  let(:connection) { PactBroker::Pacts::PactVersion.db }

  def create_version(consumer, content)
    td.create_consumer(consumer).create_provider("p#{consumer}").create_consumer_version("1")
      .create_pact(json_content: content)
    PactBroker::Pacts::PactVersion.where(sha: td.pact.pact_version_sha).get(:id)
  end

  def flags(id)
    connection[:pact_versions].where(id: id).select(:has_messages, :has_http_interactions).first
  end

  let!(:v3_messages) { create_version("a", pact_json(version: "3.0", messages: [{ "description" => "m" }])) }
  let!(:v4_http) { create_version("b", pact_json(version: "4.0", interactions: [http])) }
  let!(:v4_mixed) { create_version("c", pact_json(version: "4.0", interactions: [http, message])) }
  let!(:v4_no_version) { create_version("d", pact_json(version: nil, interactions: [message])) }
  let!(:v4_empty) { create_version("e", pact_json(version: "4.0")) }
  let!(:v2_http) { create_version("f", pact_json(version: "2.0", interactions: [untyped_http])) }
  let(:all_ids) { [v3_messages, v4_http, v4_mixed, v4_no_version, v4_empty, v2_http] }

  let(:expected) do
    {
      v3_messages => { has_messages: true, has_http_interactions: false },
      v4_http => { has_messages: false, has_http_interactions: true },
      v4_mixed => { has_messages: true, has_http_interactions: true },
      v4_no_version => { has_messages: true, has_http_interactions: false },
      v4_empty => { has_messages: false, has_http_interactions: false },
      v2_http => { has_messages: false, has_http_interactions: true }
    }
  end

  before do
    connection[:pact_versions].where(id: all_ids).update(has_http_interactions: nil)
    # Stale has_messages values in both directions, so the fill must recompute the flag.
    connection[:pact_versions].where(id: v4_no_version).update(has_messages: false)
    connection[:pact_versions].where(id: v4_http).update(has_messages: true)
  end

  it "sets both flags on every row with a NULL has_http_interactions" do
    described_class.call(connection)

    expected.each { |id, flag_values| expect(flags(id)).to eq(flag_values) }
  end

  it "recomputes messages_count and interactions_count from the interaction types" do
    # Stale counts on every row, so the fill must recompute them.
    connection[:pact_versions].where(id: all_ids).update(messages_count: 9, interactions_count: 9)

    described_class.call(connection)

    counts = connection[:pact_versions].where(id: all_ids).as_hash(:id, [:messages_count, :interactions_count])
    expect(counts).to eq(
      v3_messages => [1, 0],
      v4_http => [0, 1],
      v4_mixed => [1, 1],
      v4_no_version => [1, 0],
      v4_empty => [0, 0],
      v2_http => [0, 1]
    )
  end

  it "leaves a row that already has has_http_interactions set untouched" do
    connection[:pact_versions].where(id: v4_http).update(has_http_interactions: true, has_messages: true)
    connection[:pact_versions].where(id: v4_mixed).update(has_http_interactions: false, has_messages: false)

    described_class.call(connection)

    expect(flags(v4_http)).to eq(has_messages: true, has_http_interactions: true)
    expect(flags(v4_mixed)).to eq(has_messages: false, has_http_interactions: false)
  end

  it "fills every row when there are several batches" do
    stub_const("PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags::BATCH_SIZE", 2)

    described_class.call(connection)

    expected.each { |id, flag_values| expect(flags(id)).to eq(flag_values) }
  end

  it "reads the content of one row per query" do
    sql = []
    allow(connection).to receive(:log_connection_yield).and_wrap_original do |original, statement, *args, &block|
      sql << statement.to_s
      original.call(statement, *args, &block)
    end

    described_class.call(connection)

    content_reads = sql.grep(/\ASELECT .*content/i)
    expect(content_reads.size).to eq all_ids.size
    expect(content_reads).to all(match(/WHERE \(.?id.? = \d+\) LIMIT 1/))
  end

  it "changes nothing when run a second time" do
    described_class.call(connection)

    expect { described_class.call(connection) }.not_to change { all_ids.map { |id| flags(id) } }
  end

  it "returns nil" do
    expect(described_class.call(connection)).to be_nil
  end

  describe "logging" do
    before { allow(described_class.logger).to receive(:info) }

    it "logs the running count after each page" do
      stub_const("PactBroker::DB::DataMigrations::SetPactVersionInteractionFlags::BATCH_SIZE", 4)

      described_class.call(connection)

      expect(described_class.logger).to have_received(:info).with("Set interaction flags on 4 pact versions so far, up to id #{all_ids.sort[3]}")
      expect(described_class.logger).to have_received(:info).with("Set interaction flags on 6 pact versions so far, up to id #{all_ids.max}")
    end

    it "logs the number of rows it filled" do
      described_class.call(connection)

      expect(described_class.logger).to have_received(:info).with("Set interaction flags on 6 pact versions")
    end

    it "logs nothing at info when there are no rows to fill" do
      connection[:pact_versions].update(has_http_interactions: false)

      described_class.call(connection)

      expect(described_class.logger).not_to have_received(:info)
    end
  end

  context "when a row's content cannot be parsed" do
    # The after-each hook migrates to the latest schema, which runs the fill again.
    after { connection[:pact_versions].where(id: v4_http).update(content: pact_json(version: "4.0", interactions: [http])) }

    it "raises the parse error with the row id when the content is malformed" do
      connection[:pact_versions].where(id: v4_http).update(content: "not json")

      expect { described_class.call(connection) }.to raise_error(JSON::ParserError, /pact_versions id #{v4_http}:/)
    end

    it "raises the parse error with the row id when the content is NULL" do
      connection[:pact_versions].where(id: v4_http).update(content: nil)

      expect { described_class.call(connection) }.to raise_error(TypeError, /pact_versions id #{v4_http}:/)
    end
  end

  context "once the column is NOT NULL" do
    before do
      connection[:pact_versions].where(has_http_interactions: nil).update(has_http_interactions: false)
      connection.alter_table(:pact_versions) { set_column_not_null(:has_http_interactions) }
    end

    it "queries nothing on pact_versions" do
      queried = []
      allow(connection).to receive(:[]).and_wrap_original { |original, table| queried << table; original.call(table) }

      described_class.call(connection)

      expect(queried).not_to include(:pact_versions)
    end
  end
end
