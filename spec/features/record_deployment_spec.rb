#
# pact-broker record-deployment --pacticipant Foo --version 1 --environment test --end-previous-deployment
#

describe "Record deployment" do
  before do
    td.create_environment("test", uuid: "1234")
      .create_consumer("Foo")
      .create_consumer_version("1")
  end
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:version_path) { "/pacticipants/Foo/versions/1" }
  let(:version_response) { get(version_path, nil, { "HTTP_ACCEPT" => "application/hal+json" } ) }
  let(:path) do
    JSON.parse(version_response.body)["_links"]["pb:record-deployment"]
      .find{ |relation| relation["name"] == "test" }
      .fetch("href")
  end

  subject { post(path, nil, headers).tap { |it| puts it.body } }

  it { is_expected.to be_a_hal_json_created_response }

  it "returns the Location header" do
    expect(subject.headers["Location"]).to start_with "http://example.org/deployed-versions/"
  end

  it "returns the newly created deployment" do
    expect(response_body[:currentlyDeployed]).to be true
  end
end
