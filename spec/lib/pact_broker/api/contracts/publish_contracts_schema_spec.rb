require 'pact_broker/api/contracts/publish_contracts_schema'

module PactBroker
  module Api
    module Contracts
      describe PublishContractsSchema do
        let(:params) do
          {
            :pacticipantName => pacticipant_name,
            :versionNumber => version_number,
            :tags => tags,
            :branch => branch,
            :buildUrl => build_url,
            :contracts => [
              {
                :role => "consumer",
                :providerName => "Bar",
                :specification => "pact",
                :contentType => content_type,
                :content => encoded_contract
              }
            ]
          }
        end

        let(:pacticipant_name) { "Foo" }
        let(:version_number) { "34" }
        let(:tags) { ["a", "b"] }
        let(:branch) { "main" }
        let(:build_url) { "http://ci/builds/1234" }
        let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
        let(:encoded_contract) { Base64.strict_encode64(contract) }
        let(:content_type) { "application/json" }

        subject { PublishContractsSchema.call(params) }

        context "with valid params" do
          it { is_expected.to be_empty }
        end

        context "with an empty tag" do
          let(:tags) { [""] }

          its([:tags, 0]) { is_expected.to include "blank" }
        end

        context "with an empty build_url" do
          let(:build_url) { "" }

          it { is_expected.to be_empty }
        end

        context "with an invalid content type" do
          let(:content_type) { "foo" }

          its([:contracts, 0]) { is_expected.to include "one of" }
        end
      end
    end
  end
end
