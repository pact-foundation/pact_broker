require 'pact_broker/api/pact_broker_urls'

describe "Get all environments" do
  before do
    td.create_environment("test", display_name: "Test", uuid: "1234", contacts: [ { name: "Foo" } ] )
      .create_environment("prod", display_name: "Production", uuid: "5678", contacts: [ { name: "Foo" } ] )
  end
  let(:path) { PactBroker::Api::PactBrokerUrls.environments_url }
  let(:headers) { {'HTTP_ACCEPT' => 'application/hal+json'} }
  let(:response_body) { JSON.parse(last_response.body, symbolize_names: true)}

  subject { get(path, nil, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the environments" do
    subject
    expect(response_body[:_embedded][:environments].size).to be 2
  end
end
