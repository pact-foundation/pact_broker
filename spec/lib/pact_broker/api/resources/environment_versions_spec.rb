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
          let(:version) { td.use_consumer(pacticipant.name).create_consumer_version("1").and_return(:consumer_version) }
          let(:other_version) { td.use_consumer(pacticipant.name).create_consumer_version("2").and_return(:consumer_version) }

          let(:deployed_version) do
            td.use_consumer_version(version.number)
              .create_deployed_version(uuid: "1111", currently_deployed: true, version: version, environment_name: environment.name)
          end

          let(:released_version) do
            td.use_consumer_version(other_version.number)
              .create_released_version_for_consumer_version(uuid: "2222", environment_name: environment.name)
          end

          let(:other_environment_deployed_version) do
            td.use_consumer_version(version.number)
              .create_deployed_version(uuid: "3333", currently_deployed: true, version: version, environment_name: other_environment.name)
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

          context "when the pacticipant and environment exist" do
            before do
              deployed_version
              released_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            context "response body" do
              let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

              it "returns versions that have been deployed or released to the environment" do
                versions = response_body_hash[:_embedded][:versions]
                expect(versions).to be_a(Array)
                expect(versions.size).to eq 2
              end

              it "includes pb:deployed-environments and pb:released-environments links" do
                versions = response_body_hash[:_embedded][:versions]
                version_numbers = versions.map { |v| v[:number] }
                expect(version_numbers).to include("1", "2")
              end
            end
          end

          context "when there are versions in other environments" do
            before do
              deployed_version
              other_environment_deployed_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            it "only returns versions for the requested environment" do
              versions = JSON.parse(subject.body, symbolize_names: true)[:_embedded][:versions]
              expect(versions.size).to eq 1
              expect(versions.first[:number]).to eq "1"
            end
          end
        end
      end
    end
  end
end
