describe "Get integrations" do
  before do
    td.create_consumer("Foo")
      .create_provider("Bar")
      .create_integration
      .create_consumer("Apple")
      .create_provider("Pear")
      .create_integration
      .create_consumer("Dog")
      .create_provider("Cat")
      .create_integration
  end

  let(:path) { "/integrations" }
  let(:query) { nil }
  let(:response_body_hash) { JSON.parse(subject.body) }
  subject { get path, query, {"HTTP_ACCEPT" => "application/hal+json" }  }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns a json body with embedded integrations" do
    expect(response_body_hash["_embedded"]["integrations"]).to be_a(Array)
  end

  context "with pagination options" do
    let(:query) { { "size" => "2", "page" => "1" } }

    it_behaves_like "a paginated response"
  end

  context "with a query string" do
    let(:query) { { "q" => "pp" } }

    it "returns only the integrations with a consumer or provider name including the given string" do
      expect(response_body_hash["_embedded"]["integrations"]).to contain_exactly(hash_including("consumer" => hash_including("name" => "Apple")))
    end
  end

  context "as a dot file" do
    subject { get path, query, {"HTTP_ACCEPT" => "text/vnd.graphviz" } }

    it "returns a dot file" do
      expect(subject.body).to include "digraph"
      expect(subject.body).to include "Foo -> Bar"
    end
  end
end
