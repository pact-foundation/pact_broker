require 'pact_broker/matrix/row'

RSpec.describe "foo" do

  let(:db) { PactBroker::DB.connection }

  let(:query) do
    p = :all_pact_publications

    verifications_join = {
      Sequel[:verifications][:pact_verifiable_content_sha] => Sequel[p][:pact_verifiable_content_sha],
      Sequel[:verifications][:consumer_id] => Sequel[p][:consumer_id],
      Sequel[:verifications][:provider_id] => Sequel[p][:provider_id],
    }

          db[p]
            .select(
              Sequel[p][:consumer_id],
              Sequel[p][:consumer_name],
              Sequel[p][:consumer_version_id],
              Sequel[p][:consumer_version_number],
              Sequel[p][:consumer_version_order],
              Sequel[p][:id].as(:pact_publication_id),
              Sequel[p][:pact_version_id],
              Sequel[p][:pact_version_sha],
              Sequel[p][:pact_verifiable_content_sha],
              Sequel[p][:revision_number].as(:pact_revision_number),
              Sequel[p][:created_at].as(:pact_created_at),
              Sequel[p][:provider_id],
              Sequel[p][:provider_name],
              Sequel[:provider_versions][:id].as(:provider_version_id),
              Sequel[:provider_versions][:number].as(:provider_version_number),
              Sequel[:provider_versions][:order].as(:provider_version_order),
              Sequel[:verifications][:id].as(:verification_id),
              Sequel[:verifications][:success],
              Sequel[:verifications][:number].as(:verification_number),
              Sequel[:verifications][:execution_date].as(:verification_executed_at),
              Sequel[:verifications][:build_url].as(:verification_build_url)
            )
            .left_outer_join(:verifications, verifications_join)
            .left_outer_join(:versions, {Sequel[:provider_versions][:id] => Sequel[:verifications][:provider_version_id]}, {table_alias: :provider_versions})
  end

  let(:td) { TestDataBuilder.new }

  let(:json_content_1) do
    {
      interactions: [{a: 1, b: 2}, {c: 3, d: 4}]
    }.to_json
  end

  let(:json_content_2) do
    {
      interactions: [{b: 2, a: 1}, {d: 4, c: 3}]
    }.to_json
  end

  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar", json_content_1)
      .create_verification(provider_version: "2")
      .create_consumer_version("2")
      .create_pact(json_content: json_content_2)
      .create_consumer("Wiffle")
      .create_consumer_version("10")
      .create_pact(json_content: json_content_1)
  end

  def summarize row
    "#{row[:consumer_name]} v#{row[:consumer_version_number]} #{row[:provider_name]} v#{row[:provider_version_number] || '?'} #{row[:success]} #{row[:pact_verifiable_content_sha]}"
  end

  it "" do
    puts PactBroker::Domain::Verification.first.keys
    puts query.all.collect{ |it| summarize(it)} #PactBroker::Matrix::Row.all
    puts "\n"
    puts PactBroker::Matrix::Row.all
  end
end