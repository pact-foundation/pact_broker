require 'tasks/database'

describe 'migrate to pact versions (migrate 22-31)', no_db_clean: :true do

  def create table_name, params, id_column_name = :id
    database[table_name].insert(params);
    database[table_name].order(id_column_name).last
  end

  def clean table_name
    database[table_name].delete rescue puts "Error cleaning #{table_name} #{$!}"
  end

  def new_connection
    Sequel::DATABASES.clear
    DB.connection_for_env 'test'
  end

  let(:database) { new_connection }

  before do
    PactBroker::Database.delete_database_file
    PactBroker::Database.ensure_database_dir_exists
    database = new_connection
    PactBroker::Database.migrate(22)
  end

  let(:now) { DateTime.new(2017, 1, 1) }
  let(:pact_updated_at) { DateTime.new(2017, 1, 2) }
  let!(:consumer) { create(:pacticipants, {name: 'Consumer', created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: 'Provider', created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: '4.5.6', order: 2, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content) { create(:pact_version_contents, {content: {some: 'json'}.to_json, sha: '1234', created_at: now, updated_at: now}, :sha) }
  let!(:pact_1) { create(:pacts, {version_id: consumer_version_1[:id], provider_id: provider[:id], pact_version_content_sha: '1234', created_at: now, updated_at: pact_updated_at}) }
  let!(:pact_2) { create(:pacts, {version_id: consumer_version_2[:id], provider_id: provider[:id], pact_version_content_sha: '1234', created_at: now, updated_at: pact_updated_at}) }


  let(:do_migration) do
    schema1 = database.schema(:all_pacts, reload: false)
    PactBroker::Database.migrate(34)
    schema2 = database.schema(:all_pacts, reload: true)
    expect(schema1.map(&:first)).to_not eq schema2.map(&:first)
  end

  it "keeps the same number of pacts" do
    do_migration
    expect(new_connection[:all_pacts].count).to eq 2
  end

  it "uses the old updated date for the new creation date" do
    do_migration
    expect(new_connection[:all_pacts].order(:id).first[:created_at]).to eq pact_updated_at
  end

  it "sets each revision number to 1" do
    do_migration
    expect(new_connection[:all_pacts].order(:id).first[:revision_number]).to eq 1
    expect(new_connection[:all_pacts].order(:id).last[:revision_number]).to eq 1
  end

  it "migrates the values correctly for the first pact" do
    old_all_pact = new_connection[:all_pacts].order(:id).first
    old_all_pact.delete(:updated_at)
    old_all_pact.delete(:created_at)
    old_all_pact[:pact_version_sha] = old_all_pact.delete(:pact_version_content_sha)
    do_migration
    new_connection[:all_pacts]
    new_all_pact = new_connection[:all_pacts].order(:id).first
    new_all_pact.delete(:created_at)
    new_all_pact.delete(:revision_number)
    expect(new_all_pact).to eq old_all_pact
  end

  it "migrates the values correctly for the second pact" do
    old_all_pact = new_connection[:all_pacts].order(:id).last
    old_all_pact.delete(:updated_at)
    old_all_pact.delete(:created_at)
    old_all_pact[:pact_version_sha] = old_all_pact.delete(:pact_version_content_sha)
    do_migration
    new_all_pact = new_connection[:all_pacts].order(:id).last
    new_all_pact.delete(:created_at)
    new_all_pact.delete(:revision_number)
    expect(new_all_pact).to eq old_all_pact
  end

  after do
    PactBroker::Database.delete_database_file
    PactBroker::Database.ensure_database_dir_exists
    database = new_connection
    PactBroker::Database.migrate
  end
end
