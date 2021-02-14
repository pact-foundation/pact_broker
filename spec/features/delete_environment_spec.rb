require 'pact_broker/api/pact_broker_urls'

describe "Deleting an environment" do
  before do
    td.create_environment("test", uuid: "1234")
  end

  let(:path) { PactBroker::Api::PactBrokerUrls.environment_url(td.and_return(:environment)) }

  subject { delete(path, nil) }

  it "returns a 204 response" do
    subject
    expect(last_response.status).to be 204
  end
end
