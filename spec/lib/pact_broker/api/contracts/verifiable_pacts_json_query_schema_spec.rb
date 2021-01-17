require 'pact_broker/api/contracts/verifiable_pacts_json_query_schema'

module PactBroker
  module Api
    module Contracts
      describe VerifiablePactsJSONQuerySchema do
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

        subject { VerifiablePactsJSONQuerySchema.(params) }

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
              expect(subject[:consumerVersionSelectors].first).to match /can only be set.*index 0/
            end

            context "when there are multiple errors" do
              let(:consumer_version_selectors) do
                [{
                  consumer: "",
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

        context "when the consumer_version_selector is missing a tag" do
          let(:consumer_version_selectors) do
            [{}]
          end

          it "flattens the messages" do
            expect(subject[:consumerVersionSelectors].first).to eq "latest must be true, or a tag must be provided (at index 0)"
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
              consumer: ""
            }]
          end

          it "has an error" do
            expect(subject[:consumerVersionSelectors].first).to include "blank"
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

        context "when both a tag and a branch are specified" do
          let(:consumer_version_selectors) do
            [{
              latest: true,
              tag: "feat-x",
              branch: "main"
            }]
          end

          it "has an error" do
            expect(subject[:consumerVersionSelectors].first).to include "cannot specify both a tag and a branch (at index 0)"
          end
        end
      end
    end
  end
end
