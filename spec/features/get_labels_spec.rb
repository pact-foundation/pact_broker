describe "Get labels" do

  let(:path) { "/labels" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path) }

  context "when labels exists" do
    before do
      td.create_pacticipant("foo")
        .create_label("ios")
        .create_label("consumer")
        .create_pacticipant("bar")
        .create_label("ios")
        .create_label("consumer")
    end

    it "returns a 200 OK" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "returns the labels in the body" do
      expect(response_body_hash[:_embedded][:labels].map { |label| label[:name] }).to contain_exactly("ios", "consumer")
    end

    context "with pagination options" do
      subject { get(path, { "size" => "1", "page" => "1" }) }

      it "only returns the number of items specified in the page" do
        expect(response_body_hash[:_embedded][:labels].size).to eq 1
      end

      it_behaves_like "a paginated response"
    end
  end
end
