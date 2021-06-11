RSpec.describe "End support" do
  let!(:version) { td.create_consumer("Foo").create_consumer_version("1").and_return(:consumer_version) }
  let!(:test_environment) { td.create_environment("test").and_return(:environment) }
  let!(:released_version) do
    td.create_released_version_for_consumer_version(environment_name: "test", created_at: DateTime.now - 2, currently_supported: currently_supported)
      .and_return(:released_version)
  end
  let(:currently_supported) { true }
  let(:path) { PactBroker::Api::PactBrokerUrls.released_version_url(released_version) }
  let(:request_body) { { currentlySupported: false }.to_json }
  let(:response_body_hash) { JSON.parse(subject.body) }
  let(:rack_headers) do
    { "HTTP_ACCEPT" => "application/hal+json", "CONTENT_TYPE" => "application/merge-patch+json" }
  end

  subject { patch(path, request_body, rack_headers) }

  it "marks the deployed version as not currently supported" do
    expect{ subject }.to change {
      PactBroker::Deployments::ReleasedVersion.find(uuid: released_version.uuid).currently_supported
    }.from(true).to(false)
  end

  it "returns the updated resource" do
    expect(response_body_hash["currentlySupported"]).to be false
    expect(response_body_hash["supportEndedAt"]).to_not be nil
  end

  context "with an empty body" do
    let(:request_body) { {}.to_json }

    it "does nothing to the resource" do
      expect{ subject }.to_not change {
        PactBroker::Deployments::ReleasedVersion.find(uuid: released_version.uuid).values
      }
    end

    it "returns the resource" do
      expect(response_body_hash["uuid"]).to eq released_version.uuid
    end
  end

  context "when the version is already unsupported" do
    let(:currently_supported) { false }

    it "returns the resource" do
      expect(response_body_hash["currentlySupported"]).to be false
      expect(response_body_hash["supportEndedAt"]).to_not be nil
    end

    it "does not change the supportEndedAt date" do
      expect{ subject }.to_not change {
        PactBroker::Deployments::ReleasedVersion.find(uuid: released_version.uuid).support_ended_at
      }
    end

    context "when trying to mark it as currentlySupported again" do
      let(:request_body) { { currentlySupported: true }.to_json }

      its(:status) { is_expected.to eq 422 }

      it "returns an error" do
        expect(response_body_hash["errors"]["currentlySupported"].first).to include "cannot be set back"
      end
    end
  end
end
