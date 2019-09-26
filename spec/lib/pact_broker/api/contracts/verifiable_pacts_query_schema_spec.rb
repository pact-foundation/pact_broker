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
            tag: "master"
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
      end
    end
  end
end
