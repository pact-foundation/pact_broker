describe "Get pacticipant branches" do
  before do
    td.create_consumer("Foo")
      .create_consumer_version("1", branch: "main")
      .create_consumer_version("2", branch: "feat/bar")
      .create_consumer_version("3", branch: "feat/foo")
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.pacticipant_branches_url(td.and_return(:pacticipant)) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:params) { nil }

  subject { get(path, params, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns a list of branches" do
    expect(response_body_hash[:_embedded][:branches].size).to eq 3
  end

  it_behaves_like "a page"

  context "with pagination options" do
    subject { get(path, { "size" => "2", "number" => "1" }) }

    it "only returns the number of items specified in the size" do
      expect(response_body_hash[:_links][:"pb:branches"].size).to eq 2
    end

    it_behaves_like "a paginated response"
  end

  context "with filter options" do
    let(:params) { { "q" => "feat" } }

    it "returns a list of branches matching the filter" do
      expect(response_body_hash[:_embedded][:branches].size).to eq 2
    end
  end

  context "when the pacticipant does not exist" do
    let(:path) { PactBroker::Api::PactBrokerUrls.pacticipant_branches_url(OpenStruct.new(name: "Bar")) }

    its(:status) { is_expected.to eq 404 }
  end
end
