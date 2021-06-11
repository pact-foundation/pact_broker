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
  let(:target) { nil }
  let(:path) do
    JSON.parse(version_response.body)["_links"]["pb:record-release"]
      .find{ |relation| relation["name"] == "production" }
      .fetch("href")
  end

  subject { post(path, nil, headers) }

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

    it "returns the Location header" do
      expect(subject.headers["Location"]).to include "1234"
    end

    it "does not change the overall count of released versions" do
      expect { subject }.to_not change { PactBroker::Deployments::ReleasedVersion.count }
    end

    it "returns the existing released version" do
      expect(response_body[:uuid]).to eq "1234"
    end

    it { is_expected.to be_a_hal_json_success_response }
  end

  context "when the version is currently unsupported" do
    before do
      td.create_released_version_for_consumer_version(uuid: "1234", currently_supported: false)
    end

    it "returns the Location header" do
      expect(subject.headers["Location"]).to include "1234"
    end

    it "returns the existing release with the currentlySupported parameter set back to true" do
      expect(response_body[:currentlySupported]).to be true
    end

    it "does not change the createdAt" do
      expect { subject }.to_not change { PactBroker::Deployments::ReleasedVersion.find(uuid: "1234").created_at }
    end

    it "updates the updatedAt" do
      expect { subject }.to change { PactBroker::Deployments::ReleasedVersion.find(uuid: "1234").updated_at }
    end
  end

  it "creates a released version resource" do
    get(subject.headers["Location"])
    expect(last_response.status).to eq 200
  end
end
