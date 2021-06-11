require "pact_broker/ui/app"

describe "UI matrix" do
  let(:app) { PactBroker::UI::App.new }
  let(:td) { TestDataBuilder.new }
  let(:params) { {} }

  before do
    td.create_pact_with_verification("Foo", "1", "Bar", "2")
      .create_consumer_version_tag("ctag")
      .create_provider_version_tag("ptag")
  end

  subject { get("/matrix/provider/Bar/consumer/Foo") }

  describe "GET" do
    it "returns a success response" do
      expect(subject.status).to eq 200
    end

    it "returns the matrix page" do
      expect(subject.body).to include("Matrix")
    end

    it "returns a table of matrix rows" do
      expect(subject.body.scan("<tr").to_a.size).to be > 1
    end
  end

  describe "with query params, for the latest tagged versions of two pacticipants" do
    subject { get("/matrix?q%5B%5Dpacticipant=Foo&q%5B%5Dtag=ctag&q%5B%5Dlatest=true&q%5B%5Dpacticipant=Bar&q%5B%5Dtag=ptag&q%5B%5Dlatest=true&latestby=cvpv&limit=100") }

    it "returns a page with a badge" do
      expect(subject.body).to include "/matrix/provider/Bar/latest/ptag/consumer/Foo/latest/ctag/badge.svg"
    end
  end
end
