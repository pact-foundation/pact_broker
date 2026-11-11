require "spec/support/test_data_builder"

describe "Get versions" do
  let(:path) { "/pacticipants/Consumer/versions" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path) }

  context "when the pacticipant exists" do
    before do
      td.create_consumer("Consumer")
        .create_consumer_version("1.0.0")
        .create_consumer_version("1.0.1")
    end

    it "returns a 200 response" do
      expect(subject.status).to be 200
    end

    it "returns a list of links to the versions" do
      expect(last_response_body[:_links][:"versions"].size).to eq 2
    end

    it "does not to contain page details" do
      expect(last_response_body).not_to have_key(:page)
    end

    context "with pagination options" do
      subject { get(path, { "size" => "1", "page" => "1" }) }

      it "paginates the response" do
        expect(last_response_body[:_links][:"versions"].size).to eq 1
      end

      it "includes the pagination relations" do
        expect(last_response_body[:_links]).to have_key(:next)
      end

      it "includes the page section" do
        expect(last_response_body).to have_key(:page)
      end
    end
  end

  context "when the pacticipant does not exist" do
    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end
  end

  context "performance: should not generate N+1 queries with multiple versions and pacts" do
    before do
      # Create test data that triggers N+1 issue:
      # - 1 consumer with multiple versions
      # - Each version has pacts to multiple providers
      # - Each version has tags (triggers head_tag_names queries)
      td.create_consumer("PerfConsumer")
        .create_provider("Provider1")
        .create_provider("Provider2")
        .create_provider("Provider3")
        .create_provider("Provider4")

      50.times do |i|
        td.create_consumer_version("#{i+1}")
          .create_consumer_version_tag("prod")
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

    it "returns versions without excessive queries" do
      perf_consumer = PactBroker::Domain::Pacticipant.find(name: "PerfConsumer")
      perf_path = "/pacticipants/#{perf_consumer.name}/versions"

      # Query counting is done inside the test (not in before/after hooks) because:
      # 1. We only want to count queries during the actual HTTP request
      # 2. We don't want to count queries from test setup (finding consumer, etc.)
      queries_during_request = count_select_queries { get(perf_path, { "pageNumber" => "1", "pageSize" => "20" }) }
      response = last_response

      expect(response.status).to eq(200)

      body = JSON.parse(response.body)
      versions = body.dig("_embedded", "versions") || []
      pact_versions_links = versions.flat_map { |v| v.dig("_links", "pb:pact-versions") || [] }

      expect(versions.size).to eq(20)
      expect(pact_versions_links.size).to eq(80)

      # Without fix: 410 queries
      # After fix: 19 queries
      puts "Versions endpoint query count: #{queries_during_request}"
      expect(queries_during_request).to be < 50,
        "Expected fewer than 50 queries, got #{queries_during_request}"
    end
  end
end
