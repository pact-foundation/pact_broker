
module PactBroker
  module Api
    module Resources
      describe Version do
        let(:path) { "/pacticipants/Foo/versions/1" }

        context "with an empty body" do
          subject { put(path, nil, "CONTENT_TYPE" => "application/json") }

          its(:status) { is_expected.to eq 201 }
        end

        context "with invalid JSON" do
          subject { put(path, { some: "yaml" }.to_yaml, "CONTENT_TYPE" => "application/json") }

          its(:status) { is_expected.to eq 400 }
        end

        describe "GET" do
          let(:pacticipant) { td.create_consumer("Foo").and_return(:pacticipant) }
          let(:version) { td.use_consumer(pacticipant.name).create_consumer_version("1").and_return(:consumer_version) }
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
            its(:body) { expect(JSON.parse(subject.body, symbolize_names: true)[:error]).to include "The requested document was not found" }
          end

          context "when the pacticipant and version exist" do
            before do
              # Create a version on a pacticipant
              deployed_version
            end
            subject { get(path, nil, { "HTTP_ACCEPT" => "application/hal+json" }) }

            its(:status) { is_expected.to eq 200 }

            context "response body" do
              let(:response_body_hash) { JSON.parse(subject.body, symbolize_names: true) }

              it "contains the expected keys" do
                expect(response_body_hash).to include(:_links, :_embedded)
                expect(response_body_hash[:_links]).to include(:self, :"pb:pacticipant")
                expect(response_body_hash[:_links][:self]).to include(:title, :name, :href)
                expect(response_body_hash[:_links][:"pb:pacticipant"]).to include(:title, :name, :href)
                expect(response_body_hash[:_links][:"pb:pacticipant"][:name]).to eq "Foo"
                expect(response_body_hash[:_links][:"pb:deployed-environments"]).to be_a(Array)
                expect(response_body_hash[:_links][:"pb:deployed-environments"].size).to eq 2
                expect(response_body_hash[:_links][:"pb:deployed-environments"].first).to include(:title, :name, :href)
              end
            end
          end
        end
      end
    end
  end
end
