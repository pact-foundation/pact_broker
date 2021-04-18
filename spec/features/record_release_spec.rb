#
# pact-broker record-release --pacticipant Foo --version 1 --environment production
#

describe "Record release" do
  before do
    td.create_environment("production", uuid: "1234")
      .create_consumer("Foo")
      .create_consumer_version("1")
  end
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:version_path) { "/pacticipants/Foo/versions/1" }
  let(:version_response) { get(version_path, nil, { "HTTP_ACCEPT" => "application/hal+json" } ) }
  let(:replaced_previous) { true }
  let(:target) { nil }
  let(:path) do
    JSON.parse(version_response.body)["_links"]["pb:record-release"]
      .find{ |relation| relation["name"] == "production" }
      .fetch("href")
  end
  let(:request_body) { nil }

  subject { post(path, request_body, headers) }

  it { is_expected.to be_a_hal_json_created_response }

  it "returns the Location header" do
    expect(subject.headers["Location"]).to start_with "http://example.org/released-versions/"
  end

  it "returns the newly created release" do
    expect(response_body[:currentlySupported]).to be true
  end

  it "creates a new released version" do
    expect { subject }.to change { PactBroker::Deployments::ReleasedVersion.count }.by(1)
  end

  context "when the version is already released" do
    before do
      td.create_released_version_for_consumer_version(uuid: "1234")
    end

    it "does not change the overall count of released versions" do
      expect { subject }.to_not change { PactBroker::Deployments::ReleasedVersion.count }
    end

    it "returns the existing released version" do
      expect(response_body[:uuid]).to eq "1234"
    end

    it { is_expected.to be_a_hal_json_success_response }
  end
end
