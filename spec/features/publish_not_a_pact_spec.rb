describe "Publishing a contract that is not a pact" do

  let(:path) { "/pacts/provider/A%20Provider/consumer/A%20Consumer/versions/1.2.3" }
  let(:parsed_response_body) { JSON.parse(subject.body) }

  subject { put path, pact_content, {"CONTENT_TYPE" => "application/json" }; last_response  }

  context "when the pact is another type of CDC that doesn't have the Consumer or Provider names in the expected places" do
    let(:pact_content) { {a: "not pact"}.to_json }

    it "accepts the un-pact Pact" do
      expect(subject.status).to be 201
    end

    it "returns the content" do
      expect(parsed_response_body).to include "a" => "not pact"
    end

    it "returns _links" do
      expect(parsed_response_body).to have_key "_links"
    end
  end

  context "when the content is an array" do

    let(:pact_content) { "[1]" }

    it "accepts the un-pact Pact" do
      expect(subject.status).to be 201
    end

    it "returns the content" do
      expect(parsed_response_body).to eq [1]
    end

  end
end
