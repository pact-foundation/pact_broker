RSpec.describe "Get currently supported versions for environment" do
  let!(:version) { td.create_consumer("Foo").create_consumer_version("1").and_return(:consumer_version) }
  let!(:test_environment) { td.create_environment("test").and_return(:environment) }
  let!(:prod_environment) { td.create_environment("prod").and_return(:environment) }
  let!(:released_version) do
    td.create_released_version_for_consumer_version(environment_name: "test", created_at: DateTime.now - 2)
      .create_released_version_for_consumer_version(environment_name: "prod", created_at: DateTime.now - 1)
      .create_provider("Bar")
      .create_provider_version("4")
      .create_released_version_for_provider_version(environment_name: "test")
      .create_provider_version("5")
      .create_released_version_for_provider_version(environment_name: "test")
  end

  let(:path) do
    PactBroker::Api::PactBrokerUrls.currently_supported_versions_for_environment_url(test_environment)
  end

  let(:query_params) { {} }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, query_params, { "HTTP_ACCEPT" => "application/hal+json" }) }

  it "returns a list of released versions" do
    expect(response_body_hash[:_embedded][:releasedVersions]).to be_a(Array)
    expect(response_body_hash[:_embedded][:releasedVersions].size).to eq 3
    expect(response_body_hash[:_links][:self][:title]).to eq "Currently supported versions in Test"
    expect(response_body_hash[:_links][:self][:href]).to end_with(path)
  end

  context "with query params" do
    context "with a pacticipant name and version" do
      let(:query_params) { { pacticipant: "Bar", version: "4" } }

      it "returns a list of matching released versions" do
        expect(response_body_hash[:_embedded][:releasedVersions].size).to eq 1
        expect(response_body_hash[:_embedded][:releasedVersions].first[:_embedded][:version][:number]).to eq "4"
      end
    end

    context "with pacticipant name and no version" do
      let(:query_params) { { pacticipant: "Bar" } }

      it "returns a list of matching released versions" do
        expect(response_body_hash[:_embedded][:releasedVersions].size).to eq 2
      end
    end

    context "with no matching versions" do
      let(:query_params) { { pacticipant: "waffle" } }

      it "returns an emtpy list" do
        expect(response_body_hash[:_embedded][:releasedVersions]).to eq []
      end
    end
  end
end
