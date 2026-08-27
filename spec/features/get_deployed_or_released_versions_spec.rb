RSpec.describe "Get all versions that have ever been deployed or released", validate_oas: true do
  let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
  let(:environment) { td.create_environment("production").and_return(:environment) }
  let(:path) { "/pacticipants/Foo/deployed-or-released/versions" }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, {}, { "HTTP_ACCEPT" => "application/hal+json" }) }

  context "when the pacticipant does not exist" do
    its(:status) { is_expected.to eq 404 }
  end

  context "when the pacticipant exists" do
    before do
      td.use_consumer(pacticipant.name)
        .create_consumer_version("1")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
        .create_consumer_version("2")
        .create_released_version_for_consumer_version(environment_name: environment.name)
    end

    its(:status) { is_expected.to eq 200 }

    it { is_expected.to be_a_hal_json_success_response }

    it "returns all deployed and released versions" do
      versions = response_body_hash.dig(:_embedded, :versions)
      expect(versions.map { |v| v[:number] }).to match_array(["1", "2"])
    end

    it "includes deployment timestamps on deployed versions" do
      versions = response_body_hash.dig(:_embedded, :versions)
      deployed = versions.find { |v| v[:number] == "1" }
      deployed_env = deployed.dig(:_links, :"pb:deployed-environments").first
      expect(deployed_env[:deployed_at]).not_to be_nil
      expect(deployed_env[:undeployed_at]).to be_nil
    end

    it "includes release timestamps on released versions" do
      versions = response_body_hash.dig(:_embedded, :versions)
      released = versions.find { |v| v[:number] == "2" }
      released_env = released.dig(:_links, :"pb:released-environments").first
      expect(released_env[:released_at]).not_to be_nil
      expect(released_env[:support_ended_at]).to be_nil
    end
  end
end
