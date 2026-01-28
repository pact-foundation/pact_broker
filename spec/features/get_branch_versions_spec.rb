describe "Get versions for branch" do
  before do
    td.create_consumer("Foo")
      .create_consumer_version("1", branch: "main")
      .create_consumer_version("2", branch: "main")
      .create_consumer_version("3", branch: "foo")
      .create_consumer_version("4", branch: "main")
      .create_consumer("Bar")
      .create_consumer_version("1", branch: "main")
  end
  let(:branch) { PactBroker::Versions::Branch.order(:id).first }
  let(:path) { PactBroker::Api::PactBrokerUrls.branch_versions_url(branch) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, {}, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the branch versions" do
    expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 3
  end

  context "when the branch does not exist" do
    let(:path) { PactBroker::Api::PactBrokerUrls.branch_versions_url(branch).gsub("main", "cat") }

    its(:status) { is_expected.to eq 404 }
  end

  context "with pagination options" do
    subject { get(path, { "size" => "2", "page" => "1" }) }

    it "only returns the number of items specified in the size" do
      expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 2
    end

    it_behaves_like "a paginated response"
  end

  context "performance: should not generate N+1 queries with multiple versions and pacts" do
    # This test checks that a single GET request to
    # `/pacticipants/{name}/branches/{branch}/version` does not generate an
    # excessive number of database queries when there are many versions on the
    # branch, each with multiple pacts and tags.

    before do
      # Create test data that triggers N+1 issue:
      # - 1 consumer with multiple versions on same branch
      # - Each version has pacts to multiple providers
      # - Each version has tags (triggers head_tag_names queries)
      td.create_consumer("PerfConsumer")
        .create_provider("Provider1")
        .create_provider("Provider2")
        .create_provider("Provider3")
        .create_provider("Provider4")

      # Create 50 versions, each with 4 pacts and 3 tags
      # This should create 200 pact_publications total
      50.times do |i|
        td.create_consumer_version("#{i+1}", branch: "perf-test-branch")
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

      # Temporarily allow lazy loading for PactPublication so we can measure
      # query count.
      PactBroker::Pacts::PactPublication.class_eval do
        alias_method :_orig_load_associated_objects, :_load_associated_objects
        def _load_associated_objects(opts, *args, &block)
          # Call allow_lazy_load to disable the restriction for this instance
          allow_lazy_load
          _orig_load_associated_objects(opts, *args, &block)
        end
      end

      # Setup query counter in before block so it's active for the entire test
      # We'll capture the count before and after the request to isolate request queries
      # Use a local variable that will be captured in the closure
      query_count = [0] # Array so it can be mutated in the closure
      original_log_method = PactBroker::DB.connection.method(:log_connection_yield)

      PactBroker::DB.connection.define_singleton_method(:log_connection_yield) do |sql, conn, args=nil, &block|
        if sql.to_s.upcase.start_with?("SELECT") && !sql.to_s.include?("sqlite_master")
          query_count[0] += 1
        end
        original_log_method.call(sql, conn, args, &block)
      end

      # Store in instance variables so they're accessible in after block and test
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

    it "returns branch versions without excessive queries" do
      # Get the branch created by the test data
      perf_consumer = PactBroker::Domain::Pacticipant.find(name: "PerfConsumer")
      consumer_branch = PactBroker::Versions::Branch.where(
        name: "perf-test-branch",
        pacticipant_id: perf_consumer.id
      ).first
      perf_path = PactBroker::Api::PactBrokerUrls.branch_versions_url(consumer_branch)

      # Make request, capturing only queries made during this request
      queries_before_request = @query_count[0]
      response = get(perf_path, { "pageNumber" => "1", "pageSize" => "20" })
      queries_during_request = @query_count[0] - queries_before_request

      # Verify response is successful
      expect(response.status).to eq(200)

      body = JSON.parse(response.body)
      versions = body.dig("_embedded", "versions") || []
      pact_versions_links = versions.flat_map { |v| v.dig("_links", "pb:pact-versions") || [] }

      # Verify we got data back
      expect(versions.size).to eq(20)
      expect(pact_versions_links.size).to eq(80) # 20 versions × 4 pacts each

      # Without fix: 415 queries
      # After fix: 24 queries
      puts "Branch versions endpoint query count: #{queries_during_request}"
      expect(queries_during_request).to be < 50,
        "Expected fewer than 50 queries, got #{queries_during_request}"
    end
  end
end
