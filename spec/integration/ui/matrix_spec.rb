require 'pact_broker/ui/app'

describe "UI matrix" do
  let(:app) { PactBroker::UI::App.new }
  let(:td) { TestDataBuilder.new }
  let(:params) { {} }

  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_consumer_version_tag("prod")
      .create_consumer_version("2")
      .create_pact
  end

  subject { get("/matrix/provider/Bar/consumer/Foo") }

  describe "GET" do
    it "returns a success response" do
      expect(subject.status).to eq 200
    end

    it "returns the matrix page" do
      expect(subject.body).to include ("Matrix")
    end

    it "returns a table of matrix rows" do
      expect(subject.body.scan('<tr').to_a.count).to be > 1
    end
  end
end
