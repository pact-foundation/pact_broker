require "spec_helper"
require "pact_broker/api/decorators/version_decorator"

module PactBroker
  module Api
    module Decorators
      describe VersionDecorator do
        describe "from_json" do
          let(:hash) do
            {
              buildUrl: "buildUrl",
              tags: [{ name: "main" }]
            }
          end

          subject { VersionDecorator.new(OpenStruct.new).from_json(hash.to_json) }

          it "sets the properties" do
            expect(subject.build_url).to eq "buildUrl"
            expect(subject.tags.first.name).to eq "main"
          end
        end

        describe "to_json" do
          before do
            allow(decorator).to receive(:deployed_versions_for_version_and_environment_url).and_return("http://deployed-versions")
          end

          let(:version) do
            TestDataBuilder.new
              .create_consumer("Consumer")
              .create_provider("providerA")
              .create_consumer_version("1.2.3", branch: "main")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_provider("ProviderB")
              .create_pact
              .and_return(:consumer_version)
          end

          let(:environments) do
            [
              instance_double("PactBroker::Deployments::Environment",
                uuid: "1234",
                name: "test",
                display_name: "Test"
              )
            ]
          end

          let(:base_url) { "http://example.org" }
          let(:options) { { user_options: { base_url: base_url, environments: environments } } }
          let(:decorator) { VersionDecorator.new(version) }

          subject { JSON.parse(decorator.to_json(options), symbolize_names: true) }

          it "includes a link to itself" do
            expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3"
          end

          it "includes the version number in the link" do
            expect(subject[:_links][:self][:name]).to eq "1.2.3"
          end

          it "includes its title in the link" do
            expect(subject[:_links][:self][:title]).to eq "Version"
          end

          it "includes the version number" do
            expect(subject[:number]).to eq "1.2.3"
          end

          it "includes a link to the pacticipant" do
            expect(subject[:_links][:'pb:pacticipant']).to eq title: "Pacticipant", name: "Consumer", href: "http://example.org/pacticipants/Consumer"
          end

          it "includes a link to get, create or delete a tag" do
            expect(subject[:_links][:'pb:tag']).to include href: "http://example.org/pacticipants/Consumer/versions/1.2.3/tags/{tag}", templated: true
          end

          it "includes a list of the tags" do
            expect(subject[:_embedded][:tags]).to be_instance_of(Array)
            expect(subject[:_embedded][:tags].first[:name]).to eq "prod"
          end

          it "includes the branch versions" do
            expect(subject[:_embedded][:branchVersions]).to be_instance_of(Array)
            expect(subject[:_embedded][:branchVersions].first[:name]).to eq "main"
            expect(subject[:_embedded][:branchVersions].first[:latest]).to eq true
          end

          it "includes the timestamps" do
            expect(subject[:createdAt]).to_not be nil
          end

          it "includes a list of sorted pacts" do
            expect(subject[:_links][:'pb:pact-versions']).to be_instance_of(Array)
            expect(subject[:_links][:'pb:pact-versions'].first[:href]).to include("1.2.3")
            expect(subject[:_links][:'pb:pact-versions'].first[:name]).to include("Pact between")
            expect(subject[:_links][:'pb:pact-versions'].first[:name]).to include("providerA")
            expect(subject[:_links][:'pb:pact-versions'].last[:name]).to include("ProviderB")
          end

          it "includes a link to the latest verification results for the pacts for this version" do
            expect(subject[:_links][:'pb:latest-verification-results-where-pacticipant-is-consumer'][:href]).to match(%r{http://.*/verification-results/.*/latest})
          end

          it "includes a list of environments that this version can be deployed to" do
            expect(decorator).to receive(:deployed_versions_for_version_and_environment_url).with(version, environments.first, base_url)
            expect(subject[:_links][:'pb:record-deployment']).to be_instance_of(Array)
            expect(subject[:_links][:'pb:record-deployment'].first).to eq(
              name: "test",
              title: "Record deployment to Test",
              href: "http://deployed-versions"
            )
          end
        end
      end
    end
  end
end
