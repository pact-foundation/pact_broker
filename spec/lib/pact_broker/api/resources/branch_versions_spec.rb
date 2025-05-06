require "pact_broker/api/resources/branch_versions"

module PactBroker
  module Api
    module Resources
      describe BranchVersions do
        let(:branch_name) { "main" }
        let(:path) { "/pacticipants/Foo/branches/#{branch_name}/versions/" }

        describe "GET" do
          let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
          let(:version) { 
            td.use_consumer(pacticipant.name)
              .create_consumer_version("1", branch: branch_name)
              .and_return(:consumer_version) 
          }
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

          context "when the pacticipant and version do not exist" do
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 404 }
            its(:body) { expect(JSON.parse(subject.body, symbolize_names: true)[:error]).to match(/document was not found/) }
          end

          context "when the pacticipant and version exist" do
            before do
              # Create a version on a pacticipant and other data
              deployed_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            context "response body" do
              let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

              it "contains the expected keys" do
                expect(response_body_hash).to include(:_links, :_embedded)
                expect(response_body_hash[:_links]).to include(:self, :"pb:pacticipant")
                version_links = response_body_hash[:_embedded][:"versions"]
                expect(version_links.first[:_links][:"pb:deployed-environments"]).to be_a(Array)
                expect(version_links.first[:_links][:"pb:deployed-environments"].size).to eq 2
                expect(version_links.first[:_links][:"pb:deployed-environments"].first).to include(:title, :name, :href)
              end
            end
          end
        end
      end
    end
  end
end
