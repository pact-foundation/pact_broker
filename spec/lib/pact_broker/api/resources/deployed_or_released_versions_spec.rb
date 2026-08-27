require "pact_broker/api/resources/deployed_or_released_versions"

module PactBroker
  module Api
    module Resources
      describe DeployedOrReleasedVersions do
        let(:path) { "/pacticipants/Foo/deployed-or-released/versions" }

        describe "GET" do
          let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }
          let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
          let(:other_pacticipant) { td.create_consumer("Bar").and_return(:pacticipant) }
          let(:environment) { td.create_environment("production").and_return(:environment) }
          let(:other_environment) { td.create_environment("staging").and_return(:environment) }
          let(:version_1) { td.use_consumer(pacticipant.name).create_consumer_version("1").and_return(:consumer_version) }
          let(:version_2) { td.use_consumer(pacticipant.name).create_consumer_version("2").and_return(:consumer_version) }

          let(:deployed_version) do
            td.use_consumer_version(version_1.number)
              .create_deployed_version(uuid: "1111", currently_deployed: true, version: version_1, environment_name: environment.name)
          end

          let(:released_version) do
            td.use_consumer_version(version_2.number)
              .create_released_version_for_consumer_version(uuid: "2222", environment_name: environment.name)
          end

          context "when the pacticipant does not exist" do
            subject { get("/pacticipants/Unknown/deployed-or-released/versions", nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 404 }
          end

          context "when the pacticipant exists but has no deployed or released versions" do
            before { pacticipant }
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            it "returns an empty versions array" do
              versions = response_body_hash.dig(:_embedded, :versions)
              expect(versions).to eq []
            end
          end

          context "when the pacticipant has deployed and released versions" do
            before do
              deployed_version
              released_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            it "returns all versions that have ever been deployed or released" do
              versions = response_body_hash.dig(:_embedded, :versions)
              expect(versions.map { |v| v[:number] }).to match_array(["1", "2"])
            end

            it "contains the expected HAL structure" do
              body = response_body_hash
              expect(body).to include(:_links, :_embedded)
              expect(body[:_links]).to include(:self)
            end
          end

          context "when a version has been both deployed and released" do
            before do
              deployed_version
              td.use_consumer_version(version_1.number)
                .create_released_version_for_consumer_version(uuid: "3333", environment_name: environment.name)
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            it "returns the version only once" do
              versions = response_body_hash.dig(:_embedded, :versions)
              expect(versions.size).to eq 1
              expect(versions.first[:number]).to eq "1"
            end
          end

          context "when there are versions from another pacticipant" do
            let(:other_version) { td.use_consumer(other_pacticipant.name).create_consumer_version("2").and_return(:consumer_version) }

            before do
              deployed_version
              td.use_consumer_version(other_version.number)
                .create_deployed_version(uuid: "9999", currently_deployed: true, version: other_version, environment_name: environment.name)
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            it "only returns versions for the requested pacticipant" do
              versions = response_body_hash.dig(:_embedded, :versions)
              expect(versions.size).to eq 1
              expect(versions.first[:number]).to eq "1"
            end
          end

          context "pagination" do
            let(:version_3) { td.use_consumer(pacticipant.name).create_consumer_version("3").and_return(:consumer_version) }
            let(:deployed_version_2) do
              td.use_consumer_version(version_2.number)
                .create_deployed_version(uuid: "2222", currently_deployed: true, version: version_2, environment_name: environment.name)
            end
            let(:deployed_version_3) do
              td.use_consumer_version(version_3.number)
                .create_deployed_version(uuid: "3333", currently_deployed: true, version: version_3, environment_name: environment.name)
            end

            before do
              deployed_version
              deployed_version_2
              deployed_version_3
            end
            subject { get("#{path}?page=1&size=2", nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            it "paginates the results" do
              versions = response_body_hash.dig(:_embedded, :versions)
              expect(versions.size).to eq 2
            end

            it "includes page metadata" do
              body = response_body_hash
              expect(body[:page]).to include(number: 1, size: 2, totalElements: 3, totalPages: 2)
            end
          end
        end
      end
    end
  end
end
