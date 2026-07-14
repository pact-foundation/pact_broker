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
end
