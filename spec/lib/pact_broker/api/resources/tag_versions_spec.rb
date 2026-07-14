require "pact_broker/api/resources/tag_versions"

module PactBroker
  module Api
    module Resources
      describe TagVersions do
        let(:tag_name) { "prod" }
        let(:path) { "/pacticipants/Foo/tags/#{tag_name}/versions/" }

        describe "GET" do
          let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
          let(:version) do
            td.use_consumer(pacticipant.name)
              .create_consumer_version("1")
              .create_consumer_version_tag(tag_name)
              .and_return(:consumer_version)
          end
          let(:test_environment) { td.create_environment("test").and_return(:environment) }
          let(:prod_environment) { td.create_environment("prod").and_return(:environment) }
          let(:deployed_version) do
            td.use_consumer_version(version.number)
              .create_deployed_version(
                uuid: "1234", currently_deployed: true, version: version, environment_name: test_environment.name,
                created_at: DateTime.now - 2)
              .create_deployed_version(
                uuid: "5678", currently_deployed: true, version: version, environment_name: prod_environment.name,
                created_at: DateTime.now - 1)
          end
          let(:released_version) do
            td.use_consumer_version(version.number)
              .create_released_version_for_consumer_version(uuid: "9012", environment_name: test_environment.name)
              .create_released_version_for_consumer_version(uuid: "3456", environment_name: prod_environment.name)
          end

          context "when no versions exist for the tag" do
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 404 }
          end

          context "when versions exist for the tag" do
            before do
              deployed_version
              released_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            context "response body" do
              let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

              it "contains pb:deployed-environments and pb:released-environments for each version" do
                version_links = response_body_hash[:_embedded][:versions]
                expect(version_links.first[:_links][:"pb:deployed-environments"]).to be_a(Array)
                expect(version_links.first[:_links][:"pb:deployed-environments"].size).to eq 2
                expect(version_links.first[:_links][:"pb:deployed-environments"].first).to include(:title, :name, :href)
                expect(version_links.first[:_links][:"pb:released-environments"]).to be_a(Array)
                expect(version_links.first[:_links][:"pb:released-environments"].size).to eq 2
                expect(version_links.first[:_links][:"pb:released-environments"].first).to include(:title, :name, :href)
              end
            end
          end
        end
      end
    end
  end
end
