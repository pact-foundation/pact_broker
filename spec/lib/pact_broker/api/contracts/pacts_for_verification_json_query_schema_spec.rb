require "pact_broker/api/contracts/pacts_for_verification_json_query_schema"

module PactBroker
  module Api
    module Contracts
      describe PactsForVerificationJSONQuerySchema do
        let(:params) do
          {
            providerVersionTags: provider_version_tags,
            consumerVersionSelectors: consumer_version_selectors
          }
        end

        let(:provider_version_tags) { %w[master] }

        let(:consumer_version_selectors) do
          [{
            tag: "master",
            latest: true
          }]
        end

        subject { PactsForVerificationJSONQuerySchema.(params) }

        context "when nothing is specified" do
          let(:params) { {} }

          it { is_expected.to be_empty }
        end

        context "when the params are valid" do
          it "has no errors" do
            expect(subject).to eq({})
          end
        end

        context "when the fallback tag is specified" do
          context "when latest is specified" do
            let(:consumer_version_selectors) do
              [{
                tag: "feat-x",
                fallbackTag: "master",
                latest: true
              }]
            end

            it "has no errors" do
              expect(subject).to eq({})
            end
          end

          context "when latest is not specified" do
            let(:consumer_version_selectors) do
              [{
                tag: "feat-x",
                fallbackTag: "master"
              }]
            end

            it "has an error" do
              expect(subject[:consumerVersionSelectors].first).to match(/can only be set.*index 0/)
            end

            context "when there are multiple errors" do
              let(:consumer_version_selectors) do
                [{
                  consumer: " ",
                  tag: "feat-x",
                  fallbackTag: "master"
                }]
              end

              it "merges the array" do
                expect(subject[:consumerVersionSelectors].size).to be 2
              end
            end
          end
        end

        context "when the latest version for a particular consumer is requested" do
          let(:consumer_version_selectors) do
            [{
              consumer: "Foo",
              latest: true
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when the latest version for all is requested" do
          let(:consumer_version_selectors) do
            [{
              latest: true
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when providerVersionTags is not an array" do
          let(:provider_version_tags) { true }

          it { is_expected.to have_key(:providerVersionTags) }
        end

        context "when consumerVersionSelectors is not an array" do
          let(:consumer_version_selectors) { true }

          it { is_expected.to have_key(:consumerVersionSelectors) }
        end

        context "when the consumer_version_selector is empty" do
          let(:consumer_version_selectors) do
            [{}]
          end

          it "flattens the messages" do
            expect(subject[:consumerVersionSelectors].first).to match(/must specify a value.*at index 0/)
          end
        end

        context "when the consumerVersionSelectors is missing the latest" do
          let(:consumer_version_selectors) do
            [{
              tag: "master"
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when includeWipPactsSince key exists" do
          let(:include_wip_pacts_since) { nil }
          let(:params) do
            {
              includeWipPactsSince: include_wip_pacts_since
            }
          end

          context "when it is nil" do
            it { is_expected.to have_key(:includeWipPactsSince) }
          end

          context "when it is not a date" do
            let(:include_wip_pacts_since) { "foo" }

            it { is_expected.to have_key(:includeWipPactsSince) }
          end

          context "when it is a valid date" do
            let(:include_wip_pacts_since) { "2013-02-13T20:04:45.000+11:00" }

            it { is_expected.to_not have_key(:includeWipPactsSince) }
          end
        end

        context "when a blank consumer name is specified" do
          let(:consumer_version_selectors) do
            [{
              tag: "feat-x",
              consumer: " "
            }]
          end

          it "has an error" do
            expect(subject[:consumerVersionSelectors].first).to include "consumer cannot be blank (at index 0)"
          end
        end

        context "when a consumer name is specified with a latest tag" do
          let(:consumer_version_selectors) do
            [{
              latest: true,
              tag: "feat-x",
              consumer: "foo"
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when deployed is specified" do
          let(:consumer_version_selectors) do
            [{
              deployed: true
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when released is specified" do
          let(:consumer_version_selectors) do
            [{
              released: true
            }]
          end

          it { is_expected.to be_empty }
        end


        context "when the environment is specified" do
          before do
            allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(double("environment"))
          end

          let(:consumer_version_selectors) do
            [{
              environment: "test"
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when deployed with an environment is specified" do
          before do
            allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(double("environment"))
          end

          let(:consumer_version_selectors) do
            [{
              environment: "feat",
              deployed: true
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when deployed=false with an environment is specified" do
          before do
            allow(PactBroker::Deployments::EnvironmentService).to receive(:find_by_name).and_return(double("environment"))
          end

          let(:consumer_version_selectors) do
            [{
              environment: "feat",
              deployed: false
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "deployed must be one of: true (at index 0)" }
        end

        context "when the environment is specified and deployed is nil" do
          let(:consumer_version_selectors) do
            [{
              environment: "feat",
              deployed: nil
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "deployed must be filled (at index 0)" }
        end

        context "when deployed is nil" do
          let(:consumer_version_selectors) do
            [{
              deployed: nil
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "deployed must be filled (at index 0)" }
        end

        context "when latest=true and an environment is specified" do
          let(:consumer_version_selectors) do
            [{
              environment: "feat",
              latest: true
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "cannot specify the field latest with the field environment (at index 0)" }
        end

        context "when latest=true, tag and an environment and deployed are specified" do
          let(:consumer_version_selectors) do
            [{
              environment: "feat",
              latest: true,
              tag: "foo",
              deployed: true
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "cannot specify the fields latest/tag with the fields deployed/environment (at index 0)" }
        end

        context "when a tag and a branch are specified" do
          let(:consumer_version_selectors) do
            [{
              branch: "foo",
              tag: "foo",
              latest: true
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "cannot specify both a tag and a branch (at index 0)" }
        end

        context "when a fallbackTag is specified without a tag" do
          let(:consumer_version_selectors) do
            [{
              fallbackTag: "foo",
              latest: true,
              branch: "foo"
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "a tag must be specified when a fallbackTag is specified (at index 0)" }
        end

        context "when a fallbackBranch is specified without a branch" do
          let(:consumer_version_selectors) do
            [{
              fallbackBranch: "foo",
              tag: "foo"
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "a branch must be specified when a fallbackBranch is specified (at index 0)" }
        end

        context "when a branch is specified with no latest=true" do
          let(:consumer_version_selectors) do
            [{
              branch: "foo"
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when a branch is specified with latest=false" do
          let(:consumer_version_selectors) do
            [{
              branch: "foo",
              latest: false
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "cannot specify a branch with latest=false (at index 0)" }
        end

        context "when the environment does not exist" do
          let(:environment) { nil }

          let(:consumer_version_selectors) do
            [{ environment: "prod" }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to eq "environment with name 'prod' does not exist (at index 0)" }
        end

        context "when the environment name does not pass schema validation" do
          let(:environment) { nil }

          let(:consumer_version_selectors) do
            [{ environment: 1 }]
          end

          it "does not attempt to look up the environment" do
            expect(PactBroker::Deployments::EnvironmentService).to_not receive(:find_by_name)
            subject
          end
        end

        context "when matchingBranch is true, but the providerVersionBranch is not set" do
          let(:consumer_version_selectors) do
            [{
              matchingBranch: true
            }]
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to include "the providerVersionBranch must be specified"}
        end

        context "when the providerVersionBranch is a space" do
          let(:provider_version_branch) { " " }

          let(:params) do
            {
              providerVersionBranch: provider_version_branch,
              consumerVersionSelectors: consumer_version_selectors
            }
          end

          let(:consumer_version_selectors) do
            [{
              matchingBranch: true
            }]
          end

          its([:providerVersionBranch, 0]) { is_expected.to include "cannot be blank"}
        end

        context "when the providerVersionBranch is an empty string and there are tags provided" do
          let(:params) do
            {
              providerVersionBranch: provider_version_branch,
              consumerVersionSelectors: consumer_version_selectors,
              providerVersionTags: provider_version_tags
            }
          end

          let(:provider_version_branch) { "" }

          it "does not have any errors because the original schema (before dry-validation upgrade) didn't have any validation for the providerVersionBranch and if we introduce it now, we'll break everyone's builds (we know because we did it :grimace:)" do
            expect(subject).to be_empty
          end
        end

        context "when the providerVersionBranch is an empty string" do
          let(:params) do
            {
              providerVersionBranch: provider_version_branch,
              consumerVersionSelectors: consumer_version_selectors,
              includePendingStatus: include_pending_status,
              includeWipPactsSince: include_wip_pacts_since,
              providerVersionTags: provider_version_tags
            }.compact
          end

          let(:include_pending_status) { false }
          let(:include_wip_pacts_since) { nil }
          let(:provider_version_tags) { nil }
          let(:provider_version_branch) { "" }

          context "when includePendingStatus is true" do
            let(:include_pending_status) { true }

            context "there are no tags provided" do
              it "return an error because we need the branch or tags to properly calculate the pending status, and a blank string is most likely user error" do
                expect(subject[:providerVersionBranch]).to_not be_empty
              end
            end

            context "when the tags is an empty array" do
              let(:provider_version_tags) { [] }

              its([:providerVersionBranch]) { is_expected.to_not be_empty }
            end

            context "when the tags are provided" do
              let(:provider_version_tags) { ["foo"] }

              it { is_expected.to_not have_key(:providerVersionBranch) }
            end
          end

          context "when includePendingStatus is false" do
            it "does not return an error because we're not using the branch for anything anyway" do
              expect(subject).to be_empty
            end
          end

          context "when includeWipPactsSince is set" do
            let(:include_wip_pacts_since) { "2020-01-01" }

            context "there are no tags provided" do
              it "return an error because we need the branch or tags to properly calculate the pending status, and a blank string is most likely user error" do
                expect(subject[:providerVersionBranch]).to_not be_empty
              end
            end

            context "when the tags is an empty array" do
              let(:provider_version_tags) { [] }

              its([:providerVersionBranch]) { is_expected.to_not be_empty }
            end

            context "when the tags are provided" do
              let(:provider_version_tags) { ["foo"] }

              it { is_expected.to_not have_key(:providerVersionBranch) }
            end
          end

          context "when includeWipPactsSince is not set" do
            it "does not return an error because we're not using the branch for anything anyway" do
              expect(subject).to be_empty
            end
          end
        end

        context "when the providerVersionBranch is a space" do
          let(:params) do
            {
              providerVersionBranch: provider_version_branch,
              consumerVersionSelectors: consumer_version_selectors
            }
          end

          let(:provider_version_branch) { " " }

          it "does not allow it" do
            expect(subject[:providerVersionBranch]).to_not be_empty
          end
        end

        context "when mainBranch is true, and latest is false" do
          let(:params) do
            {
              consumerVersionSelectors: [ { mainBranch: true, latest: false }]
            }
          end

          its([:consumerVersionSelectors, 0]) { is_expected.to match("cannot specify") }
        end

        context "when mainBranch is true, and latest is true" do
          let(:params) do
            {
              consumerVersionSelectors: [ { mainBranch: true, latest: true }]
            }
          end

          it { is_expected.to_not have_key(:consumerVersionSelectors) }
        end
      end
    end
  end
end
