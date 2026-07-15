require "pact_broker/api/resources/environment_versions"

module PactBroker
  module Api
    module Resources
      describe EnvironmentVersions do
        let(:environment_uuid) { "11111111-1111-1111-1111-111111111111" }
        let(:path) { "/pacticipants/Foo/environments/#{environment_uuid}/versions" }

        describe "GET" do
          let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
          let(:environment) { td.create_environment("production", uuid: environment_uuid).and_return(:environment) }
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

          context "when the environment does not exist" do
            before { pacticipant }
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 404 }
          end

          context "when the pacticipant does not exist" do
            before { environment }
            subject { get("/pacticipants/Unknown/environments/#{environment_uuid}/versions", nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 404 }
          end

          context "when the environment exists but has no versions for this pacticipant" do
            before { environment; pacticipant }
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            it "returns an empty versions array" do
              versions = JSON.parse(subject.body, symbolize_names: true).dig(:_embedded, :versions)
              expect(versions).to eq []
            end
          end

          context "when the pacticipant and environment exist with deployed and released versions" do
            before do
              deployed_version
              released_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            context "response body" do
              let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

              it "contains the expected top-level HAL structure" do
                expect(response_body_hash).to include(:_links, :_embedded)
                expect(response_body_hash[:_links]).to include(:self)
                expect(response_body_hash[:_links][:self]).to include(:href)
              end

              it "returns all versions that have been deployed or released to the environment" do
                versions = response_body_hash[:_embedded][:versions]
                expect(versions).to be_a(Array)
                expect(versions.size).to eq 2
                expect(versions.map { |v| v[:number] }).to match_array(["1", "2"])
              end

              it "includes pb:deployed-environments with the correct shape on the deployed version" do
                versions = response_body_hash[:_embedded][:versions]
                deployed = versions.find { |v| v[:number] == "1" }
                expect(deployed[:_links][:"pb:deployed-environments"]).to be_a(Array)
                expect(deployed[:_links][:"pb:deployed-environments"].size).to eq 1
                expect(deployed[:_links][:"pb:deployed-environments"].first).to include(:title, :name, :href)
                expect(deployed[:_links][:"pb:deployed-environments"].first[:name]).to eq "Production"
              end

              it "includes pb:released-environments with the correct shape on the released version" do
                versions = response_body_hash[:_embedded][:versions]
                released = versions.find { |v| v[:number] == "2" }
                expect(released[:_links][:"pb:released-environments"]).to be_a(Array)
                expect(released[:_links][:"pb:released-environments"].size).to eq 1
                expect(released[:_links][:"pb:released-environments"].first).to include(:title, :name, :href)
                expect(released[:_links][:"pb:released-environments"].first[:name]).to eq "Production"
              end
            end
          end

          context "when a version has been both deployed and released to the environment" do
            before do
              td.use_consumer_version(version_1.number)
                .create_deployed_version(uuid: "1111", currently_deployed: true, version: version_1, environment_name: environment.name)
                .create_released_version_for_consumer_version(uuid: "2222", environment_name: environment.name)
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            it "returns the version only once" do
              versions = JSON.parse(subject.body, symbolize_names: true).dig(:_embedded, :versions)
              expect(versions.size).to eq 1
              expect(versions.first[:number]).to eq "1"
            end
          end

          context "when there are versions deployed to other environments" do
            before do
              deployed_version
              td.use_consumer_version(version_2.number)
                .create_deployed_version(uuid: "3333", currently_deployed: true, version: version_2, environment_name: other_environment.name)
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            it "only returns versions for the requested environment" do
              versions = JSON.parse(subject.body, symbolize_names: true).dig(:_embedded, :versions)
              expect(versions.size).to eq 1
              expect(versions.first[:number]).to eq "1"
            end
          end

          context "when there are versions released to other environments" do
            before do
              released_version
              td.use_consumer_version(version_1.number)
                .create_released_version_for_consumer_version(uuid: "3333", environment_name: other_environment.name)
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            it "only returns versions for the requested environment" do
              versions = JSON.parse(subject.body, symbolize_names: true).dig(:_embedded, :versions)
              expect(versions.size).to eq 1
              expect(versions.first[:number]).to eq "2"
            end
          end
        end
      end
    end
  end
end
