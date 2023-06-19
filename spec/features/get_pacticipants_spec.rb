describe "Get pacticipants" do

  let(:path) { "/pacticipants" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) { { name: "Foo" } }

  subject { get(path) }

  context "when pacticipants exist" do

    before do
      td.create_pacticipant("Foo")
        .create_pacticipant("Bar")
        .create_pacticipant("someOther")
    end

    it "returns a 200 OK" do
      expect(subject).to be_a_hal_json_success_response
    end

    it "does not to contain page details" do
      expect(response_body_hash).not_to have_key(:page)
    end

    context "with pagination options" do
      subject { get(path, { "pageSize" => "2", "pageNumber" => "1" }) }

      it "only returns the number of items specified in the pageSize" do
        expect(response_body_hash[:_links][:"pacticipants"].size).to eq 2
      end

      it_behaves_like "a paginated response"
    end
  end
end

