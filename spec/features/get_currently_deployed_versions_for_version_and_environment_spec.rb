# TODO CURRENTLY DEPLOYED
RSpec.describe "Get currently deployed versions for version" do
  let!(:version) { td.create_consumer("Foo").create_consumer_version("1").and_return(:consumer_version) }
  let!(:test_environment) { td.create_environment("test").and_return(:environment) }
  let!(:prod_environment) { td.create_environment("prod").and_return(:environment) }
  let!(:deployed_version) do
    td.create_deployed_version_for_consumer_version(environment_name: "test", created_at: DateTime.now - 2)
      .create_deployed_version_for_consumer_version(environment_name: "prod", created_at: DateTime.now - 1)
  end

  let(:path) do
    PactBroker::Api::PactBrokerUrls.deployed_versions_for_version_and_environment_url(
      version,
      test_environment
    )
  end

  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

  it "returns a list of deployed versions" do
    expect(response_body_hash[:_embedded][:deployedVersions]).to be_a(Array)
    expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 1
    expect(response_body_hash[:_links][:self][:title]).to eq "Deployed versions for Foo version 1"
    expect(response_body_hash[:_links][:self][:href]).to end_with(path)
  end
end
