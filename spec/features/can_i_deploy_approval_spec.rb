describe "GET /can-i-deploy approval" do
  # Foo v1 (tagged "dev") verified successfully by Bar v10 (tagged "prod"),
  # with Bar v10 deployed to the "production" environment.
  CAN_I_DEPLOY_APPROVALS = {}

  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_consumer_version_tag("dev")
      .create_verification(provider_version: "10", success: true, tag_names: ["prod"])
      .create_environment("production")
      .create_deployed_version_for_provider_version(environment_name: "production")
  end

  after do |example|
    body = JSON.parse(subject.body)
    CAN_I_DEPLOY_APPROVALS[example.full_description] = { "status" => subject.status, "summary" => body["summary"] }
  end

  after(:all) do
    Approvals.verify(CAN_I_DEPLOY_APPROVALS, name: "features_can_i_deploy_approval_spec", format: :json)
  end

  describe "can-i-deploy Foo v1 to the production environment" do
    subject { get("/can-i-deploy", { pacticipant: "Foo", version: "1", environment: "production" }, { "HTTP_ACCEPT" => "application/hal+json" }) }
    it("snapshots") { subject }
  end

  describe "can-i-deploy Foo's dev tag to Bar's prod tag (tag-to-tag URL format)" do
    subject { get("/pacticipants/Foo/latest-version/dev/can-i-deploy/to/prod", nil, { "HTTP_ACCEPT" => "application/hal+json" }) }
    it("snapshots") { subject }
  end

  describe "can-i-deploy with missing required params returns a validation error" do
    subject { get("/can-i-deploy", {}, { "HTTP_ACCEPT" => "application/hal+json" }) }
    it("snapshots") { subject }
  end

  # A second, failing integration for Foo v1, added only for these two examples, to pin the
  # `ignore` selector decision path. Baz has not been deployed to "production", so without
  # ignoring it, Foo v1 is not deployable to "production"; ignoring Baz restores the
  # already-deployable result from the shared Foo/Bar fixture above, confirming the ignore
  # selector actually alters the decision.
  describe "can-i-deploy Foo v1 to the production environment with a failing integration" do
    before do
      td.create_provider("Baz")
        .create_pact
        .create_verification(provider_version: "99", success: false)
    end

    describe "without ignoring the failing integration" do
      subject { get("/can-i-deploy", { pacticipant: "Foo", version: "1", environment: "production" }, { "HTTP_ACCEPT" => "application/hal+json" }) }
      it("snapshots") { subject }
    end

    describe "ignoring the failing integration" do
      subject { get("/can-i-deploy", { pacticipant: "Foo", version: "1", environment: "production", ignore: ["Baz"] }, { "HTTP_ACCEPT" => "application/hal+json" }) }
      it("snapshots") { subject }
    end
  end
end
