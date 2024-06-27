describe "Get labels" do

  before do
    TestDataBuilder.new
                   .create_pacticipant("foo")
                   .create_label("ios")
                   .create_label("consumer")
                   .create_pacticipant("bar")
                   .create_label("ios")
                   .create_label("consumer")
  end

  let(:path) { "/labels" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) do
    {
      labels: [
        { name: "ios" },
        { name: "consumer" }
      ]
    }
  end

  subject { get path; last_response  }

  context "when labels exists" do
    it "returns a 200 OK" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the labels in the body" do
      expect(response_body_hash[:_embedded]).to include expected_response_body
    end
  end
end
