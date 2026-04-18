require "lib/pact_broker/db/seed_example_data"

describe "retrieving the latest pact for a branch" do
  let(:path) { "/pacts/provider/Provider/consumer/Consumer/branch/main/latest" }
  let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path)  }

  before do
    seed_example_data = PactBroker::Db::SeedExampleData.new
    
    td.create_consumer("Consumer")
      .create_provider("Provider")
      .create_consumer_version("1", branch: "main")
      .create_pact
      .create_consumer_version("2", branch: "main")
      .create_pact(json_content: seed_example_data.pact_1)
      .create_consumer_version("3", branch: "foo")
      .create_pact
      .create_consumer_version("4", branch: "main")
  end

  it "returns the latest pact for the branch" do
    expect(json_response_body[:_links][:self][:href]).to end_with("2")
    expect(json_response_body[:interactions].length).to eq(1)
    expect(json_response_body[:interactions][0][:description]).to eq("a request for an alligator")
  end
end
