require 'tasks/database'

describe 'migrate to pact versions', no_db_clean: :true do

  def create table_name, params, id_column_name = :id
    Sequel::Model.db[table_name].insert(params);
    Sequel::Model.db[table_name].order(id_column_name).last
  end

  def clean table_name
    Sequel::Model.db[table_name].delete rescue puts "Error cleaning #{table_name} #{$!}"
  end

  before do
    PactBroker::Database.migrate(22)
    clean :pact_version_contents
    clean :pacts
    clean :versions
    clean :pacticipants
  end

  let(:now) { DateTime.new }
  let(:pact_updated_at) { DateTime.new + 1}
  let!(:consumer) { create(:pacticipants, {name: 'Consumer', created_at: now, updated_at: now}) }
  let!(:provider) { create(:pacticipants, {name: 'Provider', created_at: now, updated_at: now}) }
  let!(:consumer_version_1) { create(:versions, {number: '1.2.3', order: 1, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:consumer_version_2) { create(:versions, {number: '4.5.6', order: 2, pacticipant_id: consumer[:id], created_at: now, updated_at: now}) }
  let!(:pact_version_content) { create(:pact_version_contents, {content: {some: 'json'}.to_json, sha: '1234', created_at: now, updated_at: now}, :sha) }
  let!(:pact_1) { create(:pacts, {version_id: consumer_version_1[:id], provider_id: provider[:id], pact_version_content_sha: '1234', created_at: now, updated_at: pact_updated_at}) }
  let!(:pact_2) { create(:pacts, {version_id: consumer_version_2[:id], provider_id: provider[:id], pact_version_content_sha: '1234', created_at: now, updated_at: pact_updated_at}) }


  let(:do_migration) do
    PactBroker::Database.migrate(27)
    Sequel::Model.db.schema(:all_pacts, reload: true)
  end

  it "keeps the same number of pacts" do
    do_migration
    expect(Sequel::Model.db[:all_pacts].count).to eq 2
  end

  it "migrates the values correctly for the first pact" do
    old_all_pact = Sequel::Model.db[:all_pacts].order(:id).first
    old_all_pact.delete(:updated_at)
    old_all_pact.delete(:created_at)
    do_migration
    Sequel::Model.db[:all_pacts]
    new_all_pact = Sequel::Model.db[:all_pacts].order(:id).first
    new_all_pact.delete(:created_at)
    expect(new_all_pact).to eq old_all_pact
  end

  it "uses the old updated date for the new creation date" do
    do_migration
    expect(Sequel::Model.db[:all_pacts].order(:id).first[:created_at]).to eq pact_updated_at
  end

  it "migrates the values correctly for the second pact" do
    old_all_pact = Sequel::Model.db[:all_pacts].order(:id).last
    old_all_pact.delete(:updated_at)
    old_all_pact.delete(:created_at)
    do_migration
    new_all_pact = Sequel::Model.db[:all_pacts].order(:id).last
    new_all_pact.delete(:created_at)
    expect(new_all_pact).to eq old_all_pact
  end

  after do
    clean :consumer_versions_pact_versions
    clean :pact_versions
    clean :pacts
    clean :pact_version_contents
    clean :versions
    clean :pacticipants
    PactBroker::Database.migrate
  end
end