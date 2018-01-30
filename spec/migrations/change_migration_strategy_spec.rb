require 'fileutils'

describe "changing from integer to timestamp migrations", no_db_clean: true do

  TEST_DIR = "db/test/change_migration_strategy"
  DATABASE_PATH = "#{TEST_DIR}/pact_broker_database.sqlite3"
  DATABASE_CONFIG = {adapter: "sqlite", database: DATABASE_PATH, :encoding => 'utf8'}

  before do
    @db = Sequel.connect(DATABASE_CONFIG)
  end

  after do
    @db.disconnect
  end

  it "has a clean environment" do
    FileUtils.rm_rf DATABASE_PATH
  end

  def execute command
    puts command
    `#{command}`.tap { |it| puts it }
  end

  it "uses pact_broker v 2.6.0" do
    Dir.chdir(TEST_DIR) do
      Bundler.with_clean_env do
        execute('bundle install --gemfile before/Gemfile --jobs=3 --retry=3')
        expect(execute('BUNDLE_GEMFILE=before/Gemfile bundle exec rake pact_broker:version').strip).to eq '2.6.0'
      end
    end
  end

  it "migrates using integer migrations using pact_broker v2.6.0" do
    Dir.chdir(TEST_DIR) do
      Bundler.with_clean_env do
        execute('BUNDLE_GEMFILE=before/Gemfile bundle exec rake pact_broker:db:migrate[35]')
        output = execute('BUNDLE_GEMFILE=before/Gemfile bundle exec rake pact_broker:db:version')
        expect(output.strip).to eq "35"
      end
    end
  end

  it "allows data to be inserted" do
    consumer_id = @db[:pacticipants].insert(name: 'Foo', created_at: DateTime.now, updated_at: DateTime.now)
    provider_id = @db[:pacticipants].insert(name: 'Bar', created_at: DateTime.now, updated_at: DateTime.now)
    version_id = @db[:versions].insert(number: '1.2.3', order: 1, pacticipant_id: consumer_id, created_at: DateTime.now, updated_at: DateTime.now)
    pact_json = {consumer: {name: 'Foo'}, provider: {name: 'Bar'}, interactions: []}.to_json
    pact_version_id = @db[:pact_versions].insert(sha: '123', content: pact_json, created_at: DateTime.now, consumer_id: consumer_id, provider_id: provider_id)
    pact_publication_id = @db[:pact_publications].insert(consumer_version_id: version_id, provider_id: provider_id, revision_number: 1, pact_version_id: pact_version_id, created_at: DateTime.now)
  end

  it "does not have a schema_migrations table" do
    expect(@db.table_exists?(:schema_migrations)).to be false
  end

  it "migrates using timestamp migrations using pact_broker > 2.6.0" do
    Dir.chdir(TEST_DIR) do
      execute('bundle exec rake pact_broker:db:migrate')
      output = execute('bundle exec rake pact_broker:db:version')
      expect(output.strip.to_i).to be > 47
    end
  end

  it "uses the schema_migrations table after v2.6.0" do
    expect(@db.table_exists?(:schema_migrations)).to be true
    migrations_count = Dir.glob("db/migrations/**.*").select{ |f| f =~ /\/\d+/ }.count
    expect(migrations_count).to be >= 47
    expect(@db[:schema_migrations].count).to eq migrations_count
    expect(@db[:schema_migrations].order(:filename).first[:filename]).to eq '000001_create_pacticipant_table.rb'
  end

  it "doesn't need the schema_info table after this" do
    @db.drop_table(:schema_info)
  end

  it "allows rollback" do
    Dir.chdir(TEST_DIR) do
      execute('bundle exec rake pact_broker:db:migrate[45]')
      output = execute('bundle exec rake pact_broker:db:version')
      expect(output.strip).to eq "45"
    end
  end
end
