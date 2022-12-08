describe "Get pacticipants" do

  let(:path) { "/pacticipants" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
  let(:expected_response_body) { {name: "Foo"} }

  subject { get path; last_response }

  context "when the pacts exist" do

    before do
      TestDataBuilder.new
                     .create_pacticipant("Foo")
                     .create_label("ios")
                     .create_pacticipant("Bar")
                     .create_label("android")
    end

    it "returns a 200 OK" do
      expect(subject).to be_a_hal_json_success_response
    end

    context "with pagination options" do
      subject { get(path, { "pageSize" => "1", "pageNumber" => "1" }) }

      it "paginates the response" do
        expect(response_body_hash[:_links][:"pacticipants"].size).to eq 1
      end

      it "includes the pagination relations" do
        expect(response_body_hash[:_links]).to have_key(:next)
      end
    end
  end
end
