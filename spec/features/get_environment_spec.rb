require "pact_broker/api/pact_broker_urls"

describe "Get an environment" do
  before do
    td.create_environment("test", display_name: "Test", uuid: "1234", contacts: [ { name: "Foo" } ] )
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.environment_url(td.and_return(:environment)) }
  let(:headers) { {"HTTP_ACCEPT" => "application/hal+json"} }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}

  subject { get(path, nil, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the environment" do
    expect(response_body[:uuid]).to eq "1234"
    expect(response_body[:name]).to eq "test"
  end
end
