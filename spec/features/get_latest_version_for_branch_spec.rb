describe "Get latest version for branch" do
  before do
    td.create_consumer("Foo")
      .create_consumer_version("1", branch: "main")
      .create_consumer_version("2", branch: "main")
      .create_consumer_version("3", branch: "not-main")
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.latest_version_for_branch_url(PactBroker::Versions::Branch.order(:id).first) }
  let(:rack_env) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, {}, rack_env) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the latest version for the branch" do
    expect(JSON.parse(subject.body)["number"]).to eq "2"
  end
end
