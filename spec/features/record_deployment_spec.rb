#
# pact-broker record-deployment --pacticipant Foo --version 1 --environment test --replace-previous-deployed-version
#

describe "Record deployment" do
  before do
    td.create_environment("test", uuid: "1234")
      .create_consumer("Foo")
      .create_consumer_version("1")
      .create_deployed_version_for_consumer_version
  end
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:version_path) { "/pacticipants/Foo/versions/1" }
  let(:version_response) { get(version_path, nil, { "HTTP_ACCEPT" => "application/hal+json" } ) }
  let(:replaced_previous) { true }
  let(:path) do
    JSON.parse(version_response.body)["_links"]["pb:record-deployment"]
      .find{ |relation| relation["name"] == "test" }
      .fetch("href")
  end

  subject { post(path, { replacedPreviousDeployedVersion: replaced_previous }.to_json, headers) }

  it { is_expected.to be_a_hal_json_created_response }

  it "returns the Location header" do
    expect(subject.headers["Location"]).to start_with "http://example.org/deployed-versions/"
  end

  it "returns the newly created deployment" do
    expect(response_body[:currentlyDeployed]).to be true
  end

  it "marks the previous deployment as not currently deployed" do
    expect { subject }.to_not change { PactBroker::Deployments::DeployedVersion.currently_deployed.count }
  end

  context "when the deployment does not replace the previous deployed version" do
    let(:replaced_previous) { false }

    it "leaves the previous deployed version as currently deployed" do
      expect { subject }.to change { PactBroker::Deployments::DeployedVersion.currently_deployed.count }.by(1)
    end
  end
end
