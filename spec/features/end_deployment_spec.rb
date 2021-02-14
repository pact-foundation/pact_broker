#
# RPC style seems cleaner than REST here, as setting the endedAt parameter directly
# seems likely to end in Timezone tears
# This endpoint would be called by the pact broker client during `record-deployment` if the
# --end-previous-deployment (on by default) was specified.
# This allows us to know exactly what is deployed to a particular environment at a given time,
# (eg. /environments/test/deployments/current)
# and provides first class support for mobile clients that have multiple versions in prod
# at once.

describe "Record deployment ended", skip: "Not yet implemented" do
  before do
    td.create_environment("test")
      .create_pacticipant("Foo")
      .create_pacticipant_version("1")
      .create_deployment("test")
  end
  let(:path) { "/pacticipants/Foo/deployments/test/latest/end" }
  let(:headers) { {} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true) }

  subject { post(path, nil, headers) }

  it { is_expected.be_a_hal_json_success_response }

  it "returns the updated deployment" do
    expect(subject[:endedAt]).to_not be nil
  end
end
