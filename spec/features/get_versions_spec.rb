require "spec/support/test_data_builder"

describe "Get versions" do
  let(:path) { "/pacticipants/Consumer/versions" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path) }

  context "when the pacticipant exists" do
    before do
      td.create_consumer("Consumer")
        .create_consumer_version("1.0.0")
        .create_consumer_version("1.0.1")
    end

    it "returns a 200 response" do
      expect(subject.status).to be 200
    end

    it "returns a list of links to the versions" do
      expect(last_response_body[:_links][:"versions"].size).to eq 2
    end

    it "does not to contain page details" do
      expect(last_response_body).not_to have_key(:page)
    end

    context "with pagination options" do
      subject { get(path, { "pageSize" => "1", "pageNumber" => "1" }) }

      it "paginates the response" do
        expect(last_response_body[:_links][:"versions"].size).to eq 1
      end

      it "includes the pagination relations" do
        expect(last_response_body[:_links]).to have_key(:next)
      end

      it "includes the page section" do
        expect(last_response_body).to have_key(:page)
      end
    end
  end

  context "when the pacticipant does not exist" do
    it "returns a 404 response" do
      expect(subject).to be_a_404_response
    end
  end
end
