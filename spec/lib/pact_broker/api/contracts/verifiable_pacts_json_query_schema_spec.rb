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
            expect(subject[:consumerVersionSelectors].first).to eq "tag is missing at index 0"
          end
        end

        context "when the consumerVersionSelectors is missing the latest" do
          let(:consumer_version_selectors) do
            [{
              tag: "master"
            }]
          end

          it "has no errors" do
            expect(subject).to eq({})
          end
        end
      end
    end
  end
end
