RSpec.describe "Record undeployment" do
  let!(:version) { td.create_consumer("Foo").create_consumer_version("1").and_return(:consumer_version) }
  let!(:test_environment) { td.create_environment("test").and_return(:environment) }
  let!(:deployed_version) do
    td.create_deployed_version_for_consumer_version(environment_name: "test", target: "customer-1", created_at: DateTime.now - 2, currently_deployed: currently_deployed)
      .and_return(:deployed_version)
  end
  let(:currently_deployed) { true }
  let(:path) { PactBroker::Api::PactBrokerUrls.deployed_version_url(deployed_version) }
  let(:request_body) { { currentlyDeployed: false }.to_json }
  let(:response_body_hash) { JSON.parse(subject.body) }
  let(:rack_headers) do
    { "HTTP_ACCEPT" => "application/hal+json", "CONTENT_TYPE" => "application/merge-patch+json" }
  end

  subject { patch(path, request_body, rack_headers) }

  it "marks the deployed version as not currently deployed" do
    expect{ subject }.to change {
      PactBroker::Deployments::DeployedVersion.find(uuid: deployed_version.uuid).currently_deployed
    }.from(true).to(false)
  end

  it "returns the updated resource" do
    expect(response_body_hash["currentlyDeployed"]).to be false
    expect(response_body_hash["undeployedAt"]).to_not be nil
  end

  context "with an empty body" do
    let(:request_body) { {}.to_json }

    it "does nothing to the resource" do
      expect{ subject }.to_not change {
        PactBroker::Deployments::DeployedVersion.find(uuid: deployed_version.uuid).values
      }
    end

    it "returns the resource" do
      expect(response_body_hash["uuid"]).to eq deployed_version.uuid
    end
  end

  context "when the version is already undeployed" do
    let(:currently_deployed) { false }

    it "returns the resource" do
      expect(response_body_hash["currentlyDeployed"]).to be false
      expect(response_body_hash["undeployedAt"]).to_not be nil
    end

    it "does not change the undeployedAt date" do
      expect{ subject }.to_not change {
        PactBroker::Deployments::DeployedVersion.find(uuid: deployed_version.uuid).undeployed_at
      }
    end

    context "when trying to mark it as currentlyDeployed again" do
      let(:request_body) { { currentlyDeployed: true }.to_json }

      its(:status) { is_expected.to eq 422 }

      it "returns an error" do
        expect(response_body_hash["errors"]["currentlyDeployed"].first).to include "cannot be set back"
      end
    end
  end
end
