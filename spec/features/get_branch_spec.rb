describe "Get a branch" do
  before do
    td.create_consumer("Foo")
      .create_consumer_version("1234", branch: "main")
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.branch_url(PactBroker::Versions::Branch.first) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, nil, headers) }

  it { is_expected.to be_a_hal_json_success_response }
end
