require "pact_broker/api/decorators/verifiable_pacts_query_decorator"

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactsQueryDecorator do

        let(:provider_version_tags) { %w[dev] }
        let(:provider_version_branch) { "main" }

        subject { VerifiablePactsQueryDecorator.new(OpenStruct.new).from_hash(params)  }

        context "when parsing JSON params" do
          let(:params) do
            {
              "providerVersionTags" => provider_version_tags,
              "providerVersionBranch" => provider_version_branch,
              "consumerVersionSelectors" => consumer_version_selectors
            }
          end

          let(:consumer_version_selectors) do
            [{ "tag" => "dev", "ignored" => "foo", "latest" => true }]
          end

          it "parses the consumer_version_selectors to a Selectors collection" do
            expect(subject.consumer_version_selectors).to be_a(PactBroker::Pacts::Selectors)
          end

          it "parses the provider version branch" do
            expect(subject.provider_version_branch).to eq "main"
          end

          context "when latest is not specified" do
            let(:consumer_version_selectors) do
              [{ "tag" => "dev" }]
            end

            it "defaults to nil" do
              expect(subject.consumer_version_selectors.first.latest).to be nil
            end
          end

          context "with a fallback" do
            let(:consumer_version_selectors) do
              [{ "tag" => "feat-x", "fallbackTag" => "dev", "latest" => true }]
            end

            it "sets the fallback" do
              expect(subject.consumer_version_selectors.first.fallback_tag).to eq "dev"
            end
          end

          it "parses the latest as a boolean" do
            expect(subject.consumer_version_selectors.first).to eq PactBroker::Pacts::Selector.new(tag: "dev", latest: true)
          end

          context "when there are no consumer_version_selectors" do
            let(:params) { {} }

            it "returns an empty array" do
              expect(subject.consumer_version_selectors).to eq PactBroker::Pacts::Selectors.new
            end
          end

          context "when there are no provider_version_tags" do
            let(:params) { {} }

            it "returns an empty array" do
              expect(subject.provider_version_tags).to eq []
            end
          end

          context "when a branch is specified but the latest is not specified" do
            let(:consumer_version_selectors) do
              [{ "branch" => "main" }]
            end

            it "defaults the latest to true" do
              expect(subject.consumer_version_selectors.first.branch).to eq "main"
              expect(subject.consumer_version_selectors.first.latest).to be true
            end
          end

          context "when an environment is specified" do
            let(:consumer_version_selectors) do
              [{ "environment" => "prod" }]
            end

            it "sets the environment" do
              expect(subject.consumer_version_selectors.first.environment).to eq "prod"
            end
          end

          context "when an environment is specified and currentlySupportedReleases is specified" do
            let(:consumer_version_selectors) do
              [{ "environment" => "prod", "currentlySupportedReleases" => true }]
            end

            it "sets the currently_supported to true and currently_deployed to nil" do
              expect(subject.consumer_version_selectors.first.environment).to eq "prod"
              expect(subject.consumer_version_selectors.first.currently_supported).to be true
            end
          end

          context "when an environment is specified and currentlyDeployed is true" do
            let(:consumer_version_selectors) do
              [{ "environment" => "prod", "currentlyDeployed" => true }]
            end

            it "sets the currently_deployed to true and currently_supported to nil" do
              expect(subject.consumer_version_selectors.first.environment).to eq "prod"
              expect(subject.consumer_version_selectors.first.currently_deployed).to be true
              expect(subject.consumer_version_selectors.first.currently_supported).to be nil
            end
          end
        end

        context "when parsing query string params" do
          let(:params) do
            {
              "provider_version_tags" => provider_version_tags,
              "consumer_version_selectors" => consumer_version_selectors
            }
          end

          let(:consumer_version_selectors) do
            [{ "tag" => "dev", "latest" => "true" }]
          end

          it "parses the provider_version_tags" do
            expect(subject.provider_version_tags).to eq provider_version_tags
          end

          it "parses a string 'latest' to a boolean" do
            expect(subject.consumer_version_selectors.first).to eq PactBroker::Pacts::Selector.new(tag: "dev", latest: true)
          end
        end

        context "when specifying include_wip_pacts_since" do
          let(:params) do
            {
              "include_wip_pacts_since" => "2013-02-13T20:04:45.000+11:00"
            }
          end

          it "parses the date" do
            expect(subject.include_wip_pacts_since).to eq DateTime.parse("2013-02-13T20:04:45.000+11:00")
          end
        end
      end
    end
  end
end
