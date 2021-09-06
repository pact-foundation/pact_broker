describe "Get a branch version" do
  before do
    td.create_consumer("Foo")
      .create_consumer_version("1234", branch: "main")
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.branch_version_url(PactBroker::Versions::BranchVersion.first) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, {}, headers) }

  it { is_expected.to be_a_hal_json_success_response }
end
