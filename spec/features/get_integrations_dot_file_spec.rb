describe "Get integrations dot file" do
  before do
    TestDataBuilder.new
      .create_pact_with_hierarchy("Foo", "1", "Bar")
  end

  let(:path) { "/integrations" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path, nil, {"HTTP_ACCEPT" => "text/vnd.graphviz" }; last_response  }

  it "returns a 200 OK" do
    expect(subject.status).to eq 200
  end

  it "returns a dot file content type" do
    expect(subject.headers["Content-Type"]).to eq "text/vnd.graphviz;charset=utf-8"
  end

  it "returns dot file content" do
    expect(subject.body).to include "Foo -> Bar"
  end
end
