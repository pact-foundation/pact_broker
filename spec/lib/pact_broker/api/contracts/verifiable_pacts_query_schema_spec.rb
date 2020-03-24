require 'pact_broker/api/contracts/verifiable_pacts_query_schema'

module PactBroker
  module Api
    module Contracts
      describe VerifiablePactsQuerySchema do
        let(:params) do
          {
            provider_version_tags: provider_version_tags,
            consumer_version_selectors: consumer_version_selectors
          }
        end

        let(:provider_version_tags) { %w[master] }

        let(:consumer_version_selectors) do
          [{
            tag: "master",
            latest: "true"
          }]
        end

        subject { VerifiablePactsQuerySchema.(params) }

        context "when the params are valid" do
          it "has no errors" do
            expect(subject).to eq({})
          end
        end

        context "when provider_version_tags is not an array" do
          let(:provider_version_tags) { "foo" }

          it { is_expected.to have_key(:provider_version_tags) }
        end

        context "when the consumer_version_selector is missing a tag" do
          let(:consumer_version_selectors) do
            [{}]
          end

          it "flattens the messages" do
            expect(subject[:consumer_version_selectors].first).to eq "tag is missing at index 0"
          end
        end

        context "when the consumer_version_selectors is missing the latest" do
          let(:consumer_version_selectors) do
            [{
              tag: "master"
            }]
          end

          it { is_expected.to be_empty }
        end

        context "when include_wip_pacts_since key exists" do
          let(:include_wip_pacts_since) { nil }
          let(:params) do
            {
              include_wip_pacts_since: include_wip_pacts_since
            }
          end

          context "when it is nil" do
            it { is_expected.to have_key(:include_wip_pacts_since) }
          end

          context "when it is not a date" do
            let(:include_wip_pacts_since) { "foo" }

            it { is_expected.to have_key(:include_wip_pacts_since) }
          end

          context "when it is a valid date" do
            let(:include_wip_pacts_since) { "2013-02-13T20:04:45.000+11:00" }

            it { is_expected.to_not have_key(:include_wip_pacts_since) }
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
            expect(subject[:consumer_version_selectors].first).to include "blank"
          end
        end
      end
    end
  end
end
