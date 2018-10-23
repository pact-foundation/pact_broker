require 'pact_broker/ui/app'

describe "UI index" do

  let(:app) { PactBroker::UI::App.new }
  let(:td) { TestDataBuilder.new }
  let(:params) { {} }

  before do
    td.create_pact_with_hierarchy("Foo", "1", "Bar")
      .create_consumer_version_tag("prod")
      .create_consumer_version("2")
      .create_pact
    get "/"
  end

  subject { get("/", params, {}); last_response }

  describe "GET" do
    it "returns a success response" do
      expect(subject.status).to eq 200
    end

    it "returns a table of pacts" do
      expect(subject.body.scan('<tr').to_a.count).to eq 2
    end

    context "with an array of tags" do
      let(:params) { { tags: ['prod'] } }

      it "returns a table of pacts with the specfied tags" do
        expect(subject.body.scan('<tr').to_a.count).to eq 3
      end
    end
  end
end
