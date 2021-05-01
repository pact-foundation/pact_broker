require 'pact_broker/api/contracts/publish_contracts_schema'

module PactBroker
  module Api
    module Contracts
      describe PublishContractsSchema do
        let(:params) do
          {
            :pacticipantName => pacticipant_name,
            :pacticipantVersionNumber => version_number,
            :tags => tags,
            :branch => branch,
            :buildUrl => build_url,
            :contracts => [
              {
                :consumerName => consumer_name,
                :providerName => "Bar",
                :specification => "pact",
                :contentType => content_type,
                :content => encoded_contract,
                :decodedContent => decoded_content,
                :decodedParsedContent => decoded_parsed_content
              }
            ]
          }
        end

        let(:pacticipant_name) { "Foo" }
        let(:consumer_name) { pacticipant_name }
        let(:version_number) { "34" }
        let(:tags) { ["a", "b"] }
        let(:branch) { "main" }
        let(:build_url) { "http://ci/builds/1234" }
        let(:contract_hash) { { "consumer" => { "name" => "Foo" }, "provider" => { "name" => "Bar" }, "interactions" => [] } }
        let(:encoded_contract) { Base64.strict_encode64(contract_hash.to_json) }
        let(:decoded_content) { contract_hash.to_json }
        let(:decoded_parsed_content) { contract_hash }
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

        context "when the specification is pact and consumer name does not match the pacticipant name" do
          let(:consumer_name) { "waffle" }

          its([:contracts, 0]) { is_expected.to include "must match" }
        end

        context "when the decoded content is nil" do
          let(:decoded_content) { nil }

          its([:contracts, 0]) { is_expected.to include "Base64" }
        end

        context "when the decoded parsed content is nil" do
          let(:decoded_parsed_content) { nil }

          its([:contracts, 0]) { is_expected.to include "The content could not be parsed as application/json" }

          context "when the content type is also nil" do
            let(:content_type) { nil }

            its([:contracts, 0]) { is_expected.to include "contentType can't be blank at index 0" }
          end
        end

        context "when the consumer name in the content does not match the pacticipant name" do
          let(:contract_hash) { { "consumer" => { "name" => "WRONG" }, "provider" => { "name" => "Bar" }, "interactions" => [] } }

          its([:contracts, 0]) { is_expected.to include "consumer name in contract content ('WRONG') must match pacticipantName ('Foo') at index 0" }
        end

        context "when there is no consumer name in the content" do
          let(:contract_hash) { {  } }

          it { is_expected.to be_empty }
        end

        context "when the consumer name in the contract node does not match the pacticipant name" do
          let(:consumer_name) { "WRONG" }

          its([:contracts, 0]) { is_expected.to include "consumerName ('WRONG') must match pacticipantName ('Foo') at index 0" }
        end

        context "when the providerName in the contract node does not match the provider name in the contract content" do
          let(:contract_hash) { { "consumer" => { "name" => "Foo" }, "provider" => { "name" => "WRONG" }, "interactions" => [] } }

          its([:contracts, 0]) { is_expected.to include "provider name in contract content ('WRONG') must match providerName ('Bar') in contracts at index 0" }
        end
      end
    end
  end
end
