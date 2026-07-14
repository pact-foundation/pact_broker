describe "GET /matrix approval" do
  # Shared fixture graph, reused by both the distilled and full-body examples:
  #
  # Foo -> Bar: v1 verified successfully by Bar v10 (no branch)
  #             v2 (branch main) verified, but failed, by Bar v20
  #             v3 (branch main) has an unverified pact revision
  # Foo -> Baz: second integration, v3 verified successfully by Baz v30,
  #             deployed to the "production" environment
  def build_matrix_fixture_graph
    td.create_pact_with_hierarchy("Foo", "1", "Bar", fixed_pact_json("Foo", "Bar", 1))
      .create_verification(provider_version: "10", success: true)
      .create_consumer_version("2", branch: "main")
      .create_pact(json_content: fixed_pact_json("Foo", "Bar", 2))
      .create_verification(provider_version: "20", success: false)
      .create_consumer_version("3", branch: "main")
      .create_pact(json_content: fixed_pact_json("Foo", "Bar", 3)) # unverified revision (no verification created)
      .create_provider("Baz")
      .create_pact(json_content: fixed_pact_json("Foo", "Baz", 1))
      .create_verification(provider_version: "30", success: true)
      .create_environment("production")
      .create_deployed_version_for_provider_version(environment_name: "production")
  end

  # The default json_content used by td#create_pact includes a random value, which
  # would make the pact_version_sha (and therefore the verification result URLs in
  # the full-body snapshot) non-deterministic across runs. Use fixed content instead.
  def fixed_pact_json(consumer_name, provider_name, differentiator)
    {
      "consumer" => { "name" => consumer_name },
      "provider" => { "name" => provider_name },
      "interactions" => [
        {
          "request" => { "method" => "GET", "path" => "/things/#{differentiator}" },
          "response" => { "status" => 200 }
        }
      ]
    }.to_json
  end

  # --- distilled decision snapshots over a production-weighted request matrix ---
  # DB-independent (deployable/reason/counts only, no raw IDs), so NOT sqlite-gated.
  describe "distilled decisions" do
    MATRIX_APPROVALS = {}

    before { build_matrix_fixture_graph }

    after do |example|
      MATRIX_APPROVALS[example.full_description] = matrix_query_content_for_approval_or_body(subject)
    end

    def matrix_query_content_for_approval_or_body(response)
      body = JSON.parse(response.body)
      {
        "status" => response.status,
        "summary" => body["summary"],
        "noticeTypes" => (body["notices"] || []).collect { |notice| notice["type"] }
      }
    end

    after(:all) do
      Approvals.verify(MATRIX_APPROVALS, name: "features_get_matrix_approval_spec", format: :json)
    end

    describe "single selector to latest (top production shape)" do
      subject { get("/matrix?q[][pacticipant]=Foo&q[][version]=1&latestby=cvpv&latest=true") }
      it("snapshots") { subject }
    end

    describe "can-i-deploy to environment" do
      subject { get("/matrix?q[][pacticipant]=Foo&q[][version]=1&latestby=cvpv&environment=production") }
      it("snapshots") { subject }
    end

    describe "can-i-deploy to mainBranch" do
      subject { get("/matrix?q[][pacticipant]=Foo&q[][version]=2&latestby=cvpv&mainBranch=true") }
      it("snapshots") { subject }
    end

    describe "matrix UI browse (two selectors by name)" do
      subject { get("/matrix?q[][pacticipant]=Foo&q[][pacticipant]=Bar&latestby=cvpv") }
      it("snapshots") { subject }
    end

    describe "flat encoding, two selectors" do
      subject { get("/matrix?q[]pacticipant=Foo&q[]version=1&q[]pacticipant=Bar&q[]version=10&latestby=cvpv") }
      it("snapshots") { subject }
    end

    describe "success filter true" do
      subject { get("/matrix?q[][pacticipant]=Foo&q[][pacticipant]=Bar&latestby=cvpv&success=true") }
      it("snapshots") { subject }
    end

    describe "limit smaller than result set" do
      subject { get("/matrix?q[][pacticipant]=Foo&q[][pacticipant]=Bar&latestby=cvpv&limit=1") }
      it("snapshots") { subject }
    end

    describe "path endpoint" do
      subject { get("/matrix/provider/Bar/consumer/Foo") }
      it("snapshots") { subject }
    end
  end

  # --- full response body (public contract), pinned under sqlite only ---
  describe "full response body (public contract)" do
    before do
      build_matrix_fixture_graph
      Approvals.configure do |config|
        # determinate_headers strips "Date"/"Server"/"Content-Length" by capitalized
        # key, but Rack 3 returns lowercase header keys, so the "date" header still
        # varies run-to-run. Scrub it here, alongside the two date-bearing decorator
        # keys, following the pattern in get_provider_pacts_for_verification_spec.rb.
        config.excluded_json_keys = { timestamps: /createdAt|verifiedAt|^date$/ }
      end
    end

    subject { get("/matrix?q[][pacticipant]=Foo&q[][pacticipant]=Bar&latestby=cvpv") }

    let(:fixture) do
      {
        request: { path: "/matrix", query: "q[][pacticipant]=Foo&q[][pacticipant]=Bar&latestby=cvpv" },
        response: { status: subject.status, headers: determinate_headers(subject.headers), body: JSON.parse(subject.body) }
      }
    end

    # DB IDs differ across databases, so pin the full body under sqlite only.
    it "matches the expected body", skip: !PactBroker::TestDatabase.sqlite? do
      Approvals.verify(fixture, name: "matrix_full_body_ui_browse", format: :json)
    end
  end
end
