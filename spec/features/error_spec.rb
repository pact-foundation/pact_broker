
RSpec.describe "error handling" do
  let(:rack_headers) { {} }

  subject { post("/test/error", nil, rack_headers) }

  its(:status) { is_expected.to eq 500 }
  its(:body) { is_expected.to include "Don't panic" }

  it "returns application/hal+json" do
    expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  context "when the Accept header includes application/problem+json" do
    let(:rack_headers) do
      {
        "HTTP_ACCEPT" => "application/hal+json, application/problem+json"
      }
    end

    it "returns application/problem+json" do
      expect(subject.headers["Content-Type"]).to eq "application/problem+json;charset=utf-8"
      expect(JSON.parse(subject.body)["title"]).to eq "Server error"
    end
  end

  context "when a pacticipant does not exist" do
    subject { get("/pacticipants/foo", nil, rack_headers) }

    it "returns application/problem+json" do
      expect(subject.status).to eq 404
      expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
      expect(JSON.parse(subject.body)).to_not have_key("title")
    end

    context "when the Accept header includes application/problem+json" do
      let(:rack_headers) do
        {
          "HTTP_ACCEPT" => "application/hal+json, application/problem+json"
        }
      end

      it "returns application/problem+json" do
        expect(subject.status).to eq 404
        expect(subject.headers["Content-Type"]).to eq "application/problem+json;charset=utf-8"
        expect(JSON.parse(subject.body)["title"]).to eq "Not found"
      end
    end
  end
end
