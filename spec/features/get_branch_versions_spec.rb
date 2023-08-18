describe "Get a branch version" do
  before do
    td.create_consumer("Foo")
      .create_consumer_version("1", branch: "main")
      .create_consumer_version("2", branch: "main")
      .create_consumer_version("3", branch: "foo")
      .create_consumer_version("4", branch: "main")
      .create_consumer("Bar")
      .create_consumer_version("1", branch: "main")
  end
  let(:branch) { PactBroker::Versions::Branch.order(:id).first }
  let(:path) { PactBroker::Api::PactBrokerUrls.branch_versions_url(branch) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, {}, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the branch versions" do
    expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 3
  end

  context "when the branch does not exist" do
    let(:path) { PactBroker::Api::PactBrokerUrls.branch_versions_url(branch).gsub("main", "cat") }

    its(:status) { is_expected.to eq 404 }
  end

  context "with pagination options" do
    subject { get(path, { "pageSize" => "2", "pageNumber" => "1" }) }

    it "only returns the number of items specified in the pageSize" do
      expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 2
    end

    it_behaves_like "a paginated response"
  end
end
