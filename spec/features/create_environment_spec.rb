require "pact_broker/api/pact_broker_urls"

describe "Creating an environment" do
  let(:path) { PactBroker::Api::PactBrokerUrls.environments_url }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:response_body) { JSON.parse(subject.body, symbolize_names: true)}
  let(:environment_hash) do
    {
      name: "test",
      displayName: "Test",
      production: false,
      contacts: [
        { name: "Team Awesome", details: { email: "foo@bar.com", arbitraryThing: "thing" } }
      ]
    }
  end

  subject { post(path, environment_hash.to_json, headers) }

  it "returns a 201 response" do
    expect(subject.status).to be 201
  end

  it "returns the Location header" do
    expect(subject.headers["Location"]).to eq PactBroker::Api::PactBrokerUrls.environment_url(PactBroker::Deployments::Environment.order(:id).last, "http://example.org")
  end

  it "returns a JSON Content Type" do
    expect(subject.headers["Content-Type"]).to eq "application/hal+json;charset=utf-8"
  end

  it "returns the newly created environment" do
    expect(response_body).to include environment_hash.merge(name: "test")
    expect(response_body[:uuid]).to_not be nil
  end

  context "with invalid params" do
    before do
      td.create_environment("test")
    end

    it "returns a 400 response" do
      expect(subject.status).to be 400
      expect(response_body[:errors]).to_not be nil
    end
  end
end
