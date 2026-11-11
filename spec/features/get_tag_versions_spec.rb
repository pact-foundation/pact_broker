describe "Get versions for Pacticipant Tag" do
  before do
    td.create_consumer("Boo")
      .create_version("1.2.3")
      .create_tag("prod")
      .and_return(:tag)
    deployed_version
  end
  let(:version) { 
    td.use_consumer("Boo")
      .use_consumer_version("1.2.3")
      .and_return(:consumer_version)
  }
  let(:test_environment) { td.create_environment("test").and_return(:environment) }
  let(:prod_environment) { td.create_environment("prod").and_return(:environment) }
  let(:deployed_version) do
    td.use_consumer_version(version.number)
      .create_deployed_version(
        uuid: "1234", currently_deployed: true, version: version, environment_name: test_environment.name, 
        created_at: DateTime.now - 2)
      .create_deployed_version(
        uuid: "5678", currently_deployed: true, version: version, environment_name: prod_environment.name,
        created_at: DateTime.now - 1)
  end
  let(:tag) { PactBroker::Domain::Tag.first }
  let(:path) { PactBroker::Api::PactBrokerUrls.tag_versions_url(tag) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, {}, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the tags versions" do
    response = JSON.parse(subject.body)
    expect(response.dig("_embedded", "versions").size).to eq 1
    expect(response.dig("_embedded", "versions").first["number"]).to eq "1.2.3"
    expect(response.dig("_embedded", "versions").first["_links"]["pb:deployed-environments"].size).to eq 2
  end

  context "when the pacticipant does not exist" do 
    let(:path) { "pacticipants/Foo/tags/#{tag.name}/versions" }

    its(:status) { is_expected.to eq 404 }
  end

  context "when the tag does not exist" do
    let(:path) { "pacticipants/Boo/tags/feature_tag/versions" }

    its(:status) { is_expected.to eq 404 }
  end

  context "with pagination options" do
    subject { get(path, { "size" => "1", "page" => "1" }) }

    it "only returns the number of items specified in the size" do
      expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 1
    end

  end

  context "performance: should not generate N+1 queries with multiple versions and pacts" do
    before do
      # Create test data that triggers N+1 issue:
      # - 1 consumer with multiple versions
      # - All versions tagged with same tag
      # - Each version has pacts to multiple providers
      td.create_consumer("PerfTagConsumer")
        .create_provider("Provider1")
        .create_provider("Provider2")
        .create_provider("Provider3")
        .create_provider("Provider4")

      50.times do |i|
        td.create_consumer_version("#{i+1}")
          .create_consumer_version_tag("perf-tag")
          .create_consumer_version_tag("test")
          .create_consumer_version_tag("staging")
          .use_provider("Provider1")
          .create_pact
          .use_provider("Provider2")
          .create_pact
          .use_provider("Provider3")
          .create_pact
          .use_provider("Provider4")
          .create_pact
      end
    end

    it "returns tag versions without excessive queries" do
      perf_consumer = PactBroker::Domain::Pacticipant.find(name: "PerfTagConsumer")
      perf_tag = PactBroker::Domain::Tag.where(
        name: "perf-tag",
        pacticipant_id: perf_consumer.id
      ).first
      perf_path = PactBroker::Api::PactBrokerUrls.tag_versions_url(perf_tag)

      # Query counting is done inside the test (not in before/after hooks) because:
      # 1. We only want to count queries during the actual HTTP request
      # 2. We don't want to count queries from test setup (finding consumer, tag, etc.)
      queries_during_request = count_select_queries { get(perf_path, { "pageNumber" => "1", "pageSize" => "20" }) }
      response = last_response

      expect(response.status).to eq(200)

      body = JSON.parse(response.body)
      versions = body.dig("_embedded", "versions") || []
      pact_versions_links = versions.flat_map { |v| v.dig("_links", "pb:pact-versions") || [] }

      expect(versions.size).to eq(20)
      expect(pact_versions_links.size).to eq(80)

      # Without fix: 411 queries
      # After fix: 20 queries
      puts "Tag versions endpoint query count: #{queries_during_request}"
      expect(queries_during_request).to be < 50,
        "Expected fewer than 50 queries, got #{queries_during_request}"
    end
  end
end
