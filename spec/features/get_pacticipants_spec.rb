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

      it "paginates the response" do
        expect(response_body_hash[:_links][:"pacticipants"].size).to eq 2
      end

      it "includes the pagination relations" do
        expect(response_body_hash[:_links]).to have_key(:next)
      end

      it "includes the page section" do
        expect(response_body_hash).to have_key(:page)
      end

      it "outputs a whole number for total pages" do
        expect(response_body_hash[:page][:totalPages]).to eq(2)
      end
    end
  end
end

