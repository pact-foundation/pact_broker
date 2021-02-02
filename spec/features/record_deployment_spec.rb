#
# pact-broker record-deployment --pacticipant Foo --version 1 --environment test --end-previous-deployment
#

describe "Record deployment", skip: "Not yet implemented" do
  before do
    td.create_environment("test")
      .create_pacticipant("Foo")
      .create_pacticipant_version("1")
  end
  let(:path) { "/pacticipants/Foo/versions/1/deployments/test" }
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { post(path, nil, headers) }

  it { is_expected.to be_a_hal_json_created_response }

  it "returns the Location header" do
    subject
    expect(last_response.headers["Location"]).to eq "http://example.org/deployments/123456"
  end

  it "returns the newly created deployment" do
    subject
    expect(response_body).to include_key(:createdAt)
  end
end
