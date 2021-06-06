RSpec.describe "can i deploy" do
  before do
    td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
  end

  let(:query) do
    {
      pacticipant: "Foo",
      version: "1.2.3",
      to: "prod"
    }
  end

  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get("/can-i-deploy", query, { "HTTP_ACCEPT" => "application/hal+json"}) }

  it "returns the matrix response" do
    expect(subject).to be_a_hal_json_success_response
    expect(response_body[:matrix]).to be_instance_of(Array)
  end

  context "with a validation error" do
    let(:query) { {} }

    it "returns an error response" do
      expect(subject.status).to eq 400
      expect(response_body[:errors]).to be_instance_of(Hash)
    end
  end
end
