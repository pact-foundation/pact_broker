require "lib/pact_broker/db/seed_example_data"

describe "retrieving all pact publications for a provider, for any consumers main branch" do
  let(:path) { "/pacts/provider/Provider/branch/foo" }
  let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path)  }

  before do
    seed_example_data = PactBroker::DB::SeedExampleData.new
    
    td.create_consumer("Consumer", main_branch: "main")
      .create_provider("Provider")
      .create_consumer_version("1", branch: "main")
      .create_pact(json_content: seed_example_data.pact_1)
      .create_consumer_version("2", branch: "main")
      .create_pact(json_content: seed_example_data.pact_1)
      .create_consumer_version("3", branch: "foo")
      .create_pact(json_content: seed_example_data.pact_1)
      .create_consumer_version("4", branch: "main")
      .create_pact(json_content: seed_example_data.pact_1)
  end

  it "returns a list of latest pact publications for a provider, for any consumers main branch" do
    expect(json_response_body[:_links][:"pb:pacts"].length).to eq(1)
  end
end
