#
# pact-broker record-deployment --pacticipant Foo --version 1 --environment test --target instance1
#

describe "Record deployment" do
  before do
    td.create_environment("test", uuid: "1234")
      .create_consumer("Foo")
      .create_consumer_version("1")
      .create_deployed_version_for_consumer_version
      .create_consumer_version("2")
  end
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:version_path) { "/pacticipants/Foo/versions/2" }
  let(:version_response) { get(version_path, nil, { "HTTP_ACCEPT" => "application/hal+json" } ) }
  let(:application_instance) { nil }
  let(:path) do
    JSON.parse(version_response.body)["_links"]["pb:record-deployment"]
      .find{ |relation| relation["name"] == "test" }
      .fetch("href")
  end
  let(:request_body) { { applicationInstance: application_instance }.to_json }

  subject { post(path, request_body, headers) }

  it { is_expected.to be_a_hal_json_created_response }

  it "returns the Location header" do
    expect(subject.headers["Location"]).to start_with "http://example.org/deployed-versions/"
  end

  it "returns the newly created deployment" do
    expect(response_body[:currentlyDeployed]).to be true
    expect(response_body).to_not have_key(:target)
    expect(response_body).to_not have_key(:application_instance)
  end

  it "creates a new deployed version" do
    expect { subject }.to change { PactBroker::Deployments::DeployedVersion.count }.by(1)
  end

  it "marks the previous deployment as not currently deployed" do
    expect { subject }.to change { PactBroker::Deployments::DeployedVersion.undeployed.count }.by(1)
  end

  it "does not change the overall count of currently deployed versions" do
    expect { subject }.to_not change { PactBroker::Deployments::DeployedVersion.currently_deployed.count }
  end

  context "when the version is already currently deployed to the environment and target" do
    before do
      td.create_deployed_version_for_consumer_version(uuid: "1234")
    end

    it "does not mark anything as undeployed" do
      expect { subject }.to_not change { PactBroker::Deployments::DeployedVersion.undeployed.collect(&:uuid) }
    end

    it "returns the existing deployed version" do
      expect(response_body[:uuid]).to eq "1234"
    end
  end

  context "when the version was previously deployed to the environment and target but isn't any more" do
    before do
      td.create_deployed_version_for_consumer_version(uuid: "1234")
        .create_consumer_version("3")
        .create_deployed_version_for_consumer_version(uuid: "5678")
    end

    it "creates a new deployed version" do
      expect { subject }.to change { PactBroker::Deployments::DeployedVersion.count }.by(1)
    end
  end

  context "with an empty body" do
    let(:request_body) { nil }

    it { is_expected.to be_a_hal_json_created_response }
  end

  context "when the deployment is to a different application instance" do
    let(:application_instance) { "foo" }

    it "creates a new deployed version" do
      expect { subject }.to change { PactBroker::Deployments::DeployedVersion.currently_deployed.count }.by(1)
    end

    it "sets the applicationInstance" do
      expect(response_body).to have_key(:applicationInstance)
    end
  end

  context "when the deployment is to a different target (deprecated)" do
    let(:request_body) { { target: "foo" }.to_json }

    it "creates a new deployed version" do
      expect { subject }.to change { PactBroker::Deployments::DeployedVersion.currently_deployed.count }.by(1)
    end

    it "sets the target" do
      expect(response_body).to have_key(:target)
    end
  end
end
