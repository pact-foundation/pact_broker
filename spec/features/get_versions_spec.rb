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

      # Temporarily allow lazy loading for PactPublication so we can measure query count
      PactBroker::Pacts::PactPublication.class_eval do
        alias_method :_orig_load_associated_objects, :_load_associated_objects
        def _load_associated_objects(opts, *args, &block)
          allow_lazy_load
          _orig_load_associated_objects(opts, *args, &block)
        end
      end

      # Setup query counter
      query_count = [0]  # Array so it can be mutated in the closure
      original_log_method = PactBroker::DB.connection.method(:log_connection_yield)

      PactBroker::DB.connection.define_singleton_method(:log_connection_yield) do |sql, conn, args=nil, &block|
        if sql.to_s.upcase.start_with?("SELECT") && !sql.to_s.include?("sqlite_master")
          query_count[0] += 1
        end
        original_log_method.call(sql, conn, args, &block)
      end

      @query_count = query_count
      @original_log_method = original_log_method
    end

    after do
      # Restore original database logging method
      if @original_log_method
        PactBroker::DB.connection.define_singleton_method(:log_connection_yield, @original_log_method)
      end

      # Restore original _load_associated_objects method
      PactBroker::Pacts::PactPublication.class_eval do
        alias_method :_load_associated_objects, :_orig_load_associated_objects
        remove_method :_orig_load_associated_objects
      end
    end

    it "returns versions without excessive queries" do
      perf_consumer = PactBroker::Domain::Pacticipant.find(name: "PerfConsumer")
      perf_path = "/pacticipants/#{perf_consumer.name}/versions"

      # Query counting is done inside the test (not in before/after hooks) because:
      # 1. We only want to count queries during the actual HTTP request
      # 2. We don't want to count queries from test setup (finding consumer, etc.)
      # 3. The counter must be reset for each test run

      queries_before_request = @query_count[0]
      response = get(perf_path, { "pageNumber" => "1", "pageSize" => "20" })
      queries_during_request = @query_count[0] - queries_before_request

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
