RSpec.describe "Get currently deployed versions for environment" do
  let!(:version) { td.create_consumer("Foo").create_consumer_version("1").and_return(:consumer_version) }
  let!(:test_environment) { td.create_environment("test").and_return(:environment) }
  let!(:prod_environment) { td.create_environment("prod").and_return(:environment) }
  let!(:deployed_version) do
    td.create_deployed_version_for_consumer_version(environment_name: "test", target: "customer-1", created_at: DateTime.now - 2)
      .create_deployed_version_for_consumer_version(environment_name: "prod", created_at: DateTime.now - 1)
      .create_provider("Bar")
      .create_provider_version("4")
      .create_deployed_version_for_provider_version(environment_name: "test", target: "customer-1")
      .create_provider_version("5")
      .create_deployed_version_for_provider_version(environment_name: "test")
  end

  let(:path) do
    PactBroker::Api::PactBrokerUrls.currently_deployed_versions_for_environment_url(test_environment)
  end

  let(:query_params) { {} }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, query_params, { "HTTP_ACCEPT" => "application/hal+json" }) }

  it "returns a list of deployed versions" do
    expect(response_body_hash[:_embedded][:deployedVersions]).to be_a(Array)
    expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 3
    expect(response_body_hash[:_links][:self][:title]).to eq "Currently deployed versions for Test"
    expect(response_body_hash[:_links][:self][:href]).to end_with(path)
  end

  context "with query params" do
    context "with a pacticipant name and applicationInstance" do
      let(:query_params) { { pacticipant: "Bar", applicationInstance: "customer-1" } }

      it "returns a list of matching deployed versions" do
        expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 1
        expect(response_body_hash[:_embedded][:deployedVersions].first[:_embedded][:version][:number]).to eq "4"
      end
    end

    context "with pacticipant name and a blank applicationInstance" do
      let(:query_params) { { pacticipant: "Bar", applicationInstance: "" } }

      it "returns a list of matching deployed versions" do
        expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 1
        expect(response_body_hash[:_embedded][:deployedVersions].first[:_embedded][:version][:number]).to eq "5"
      end
    end

    context "with pacticipant name and no target or applicationInstance" do
      let(:query_params) { { pacticipant: "Bar" } }

      it "returns a list of matching deployed versions" do
        expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 2
      end
    end

    context "with a pacticipant name and target (deprecated)" do
      let(:query_params) { { pacticipant: "Bar", target: "customer-1" } }

      it "returns a list of matching deployed versions" do
        expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 1
        expect(response_body_hash[:_embedded][:deployedVersions].first[:_embedded][:version][:number]).to eq "4"
      end
    end

    context "with pacticipant name and a blank target (deprecated)" do
      let(:query_params) { { pacticipant: "Bar", target: "" } }

      it "returns a list of matching deployed versions" do
        expect(response_body_hash[:_embedded][:deployedVersions].size).to eq 1
        expect(response_body_hash[:_embedded][:deployedVersions].first[:_embedded][:version][:number]).to eq "5"
      end
    end
  end
end
