require "lib/pact_broker/db/seed_example_data"

describe "retrieving pact publications for specified branch" do
  let(:path) { "/pacts/provider/Provider/consumer/Consumer/branch/foo" }
  let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path)  }

  before do
    seed_example_data = PactBroker::DB::SeedExampleData.new
    
    td.create_consumer("Consumer", main_branch: "main")
      .create_provider("Provider")
      .create_consumer_version("1", branch: "main")
      .create_pact
      .create_consumer_version("2", branch: "main")
      .create_pact(json_content: seed_example_data.pact_1)
      .create_consumer_version("3", branch: "foo")
      .create_pact
      .create_consumer_version("4", branch: "main")
      .create_consumer_version("5", branch: "foo")
      .create_pact
  end

  it "returns the pact publications for associated consumers named branch" do
    expect(json_response_body[:_embedded][:pacts].length).to eq(2)
    expect(json_response_body[:_embedded][:pacts][0][:_embedded][:consumerVersion][:number]).to eq("3")
    expect(json_response_body[:_embedded][:pacts][1][:_embedded][:consumerVersion][:number]).to eq("5")
    expect(json_response_body[:_links][:"pact-versions"].length).to eq(2)
    expect(json_response_body[:_links][:"pact-versions"][0][:name]).to include("Version 3")
    expect(json_response_body[:_links][:"pact-versions"][1][:name]).to include("Version 5")
  end
end

describe "retrieving pact publications for specified branch" do
  let(:path) { "/pacts/provider/Provider/consumer/Consumer/branch/main" }
  let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path)  }

  before do
    seed_example_data = PactBroker::DB::SeedExampleData.new
    
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
    expect(json_response_body[:_embedded][:pacts].length).to eq(2)
    expect(json_response_body[:_embedded][:pacts][0][:_embedded][:consumerVersion][:number]).to eq("1")
    expect(json_response_body[:_embedded][:pacts][1][:_embedded][:consumerVersion][:number]).to eq("2")
    expect(json_response_body[:_links][:"pact-versions"].length).to eq(2)
    expect(json_response_body[:_links][:"pact-versions"][0][:name]).to include("Version 1")
    expect(json_response_body[:_links][:"pact-versions"][1][:name]).to include("Version 2")
  end
end
