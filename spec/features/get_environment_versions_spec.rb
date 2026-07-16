describe "Get versions for pacticipant in environment" do
  let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
  let(:environment) { td.create_environment("production", uuid: "aaaaaaaa-0000-0000-0000-000000000000").and_return(:environment) }
  let(:other_environment) { td.create_environment("staging").and_return(:environment) }

  let(:path) { PactBroker::Api::PactBrokerUrls.environment_versions_url(pacticipant, environment) }
  let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, {}, { "HTTP_ACCEPT" => "application/hal+json" }) }

  context "when the environment does not exist" do
    before { pacticipant }
    let(:path) { "/pacticipants/Foo/environments/bbbbbbbb-0000-0000-0000-000000000000/versions" }

    its(:status) { is_expected.to eq 404 }
  end

  context "when the pacticipant does not exist" do
    before { environment }
    let(:path) { "/pacticipants/Unknown/environments/#{environment.uuid}/versions" }

    its(:status) { is_expected.to eq 404 }
  end

  context "when the environment and pacticipant exist but there are no versions" do
    before { environment; pacticipant }

    its(:status) { is_expected.to eq 200 }

    it { is_expected.to be_a_hal_json_success_response }

    it "returns an empty versions array" do
      expect(response_body_hash.dig(:_embedded, :versions)).to eq []
    end
  end

  context "when the pacticipant has versions deployed and released to the environment" do
    before do
      td.use_consumer(pacticipant.name)
        .create_consumer_version("1")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
        .create_consumer_version("2")
        .create_released_version_for_consumer_version(environment_name: environment.name)
    end

    its(:status) { is_expected.to eq 200 }

    it "returns both the deployed and released versions" do
      versions = response_body_hash.dig(:_embedded, :versions)
      expect(versions.size).to eq 2
      expect(versions.map { |v| v[:number] }).to match_array(["1", "2"])
    end

    it "includes pb:deployed-environments on the deployed version" do
      versions = response_body_hash.dig(:_embedded, :versions)
      deployed = versions.find { |v| v[:number] == "1" }
      expect(deployed.dig(:_links, :"pb:deployed-environments")).not_to be_nil
    end

    it "includes pb:released-environments on the released version" do
      versions = response_body_hash.dig(:_embedded, :versions)
      released = versions.find { |v| v[:number] == "2" }
      expect(released.dig(:_links, :"pb:released-environments")).not_to be_nil
    end
  end

  context "when a version has been both deployed and released to the environment" do
    before do
      td.use_consumer(pacticipant.name)
        .create_consumer_version("1")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
        .create_released_version_for_consumer_version(environment_name: environment.name)
    end

    it "returns the version only once" do
      versions = response_body_hash.dig(:_embedded, :versions)
      expect(versions.size).to eq 1
      expect(versions.first[:number]).to eq "1"
    end
  end

  context "when there are versions for the same pacticipant in a different environment" do
    before do
      td.use_consumer(pacticipant.name)
        .create_consumer_version("1")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
        .create_consumer_version("2")
        .create_deployed_version_for_consumer_version(environment_name: other_environment.name, currently_deployed: true)
    end

    it "only returns versions for the requested environment" do
      versions = response_body_hash.dig(:_embedded, :versions)
      expect(versions.size).to eq 1
      expect(versions.first[:number]).to eq "1"
    end
  end

  context "with pagination options" do
    before do
      td.use_consumer(pacticipant.name)
        .create_consumer_version("1")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
        .create_consumer_version("2")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
        .create_consumer_version("3")
        .create_deployed_version_for_consumer_version(environment_name: environment.name, currently_deployed: true)
    end

    subject { get(path, { "size" => "2", "page" => "1" }) }

    it "only returns the number of items specified in the size" do
      expect(response_body_hash.dig(:_embedded, :versions).size).to eq 2
    end

    it_behaves_like "a paginated response"
  end
end
