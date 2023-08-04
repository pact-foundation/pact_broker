require "pact_broker/api/contracts/publish_contracts_schema"

module PactBroker
  module Api
    module Contracts
      describe PublishContractsSchema do
        include PactBroker::Test::ApiContractSupport

        let(:params) do
          {
            :pacticipantName => pacticipant_name,
            :pacticipantVersionNumber => version_number,
            :tags => tags,
            :branch => branch,
            :buildUrl => build_url,
            :contracts => contracts
          }
        end

        let(:contracts) do
          [
            {
              :consumerName => consumer_name,
              :providerName => provider_name,
              :specification => "pact",
              :contentType => content_type,
              :content => encoded_contract,
              :decodedContent => decoded_content,
              :decodedParsedContent => decoded_parsed_content
            }
          ]
        end
        let(:pacticipant_name) { "Foo" }
        let(:consumer_name) { pacticipant_name }
        let(:provider_name) { "Bar" }
        let(:version_number) { "34" }
        let(:tags) { ["a", "b"] }
        let(:branch) { "main" }
        let(:build_url) { "http://ci/builds/1234" }
        let(:contract_hash) { { "consumer" => { "name" => "Foo" }, "provider" => { "name" => "Bar" }, "interactions" => [] } }
        let(:encoded_contract) { Base64.strict_encode64(contract_hash.to_json) }
        let(:decoded_content) { contract_hash.to_json }
        let(:decoded_parsed_content) { contract_hash }
        let(:content_type) { "application/json" }

        subject { format_errors_the_old_way(PublishContractsSchema.call(params)) }

        context "with valid params" do
          it { is_expected.to be_empty }
        end

        context "with an empty tag" do
          let(:tags) { [""] }

          its([:tags, 0]) { is_expected.to include "filled" }
        end

        context "with a blank tag" do
          let(:tags) { [" "] }

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

          its([:contracts, 0]) { is_expected.to include "content could not be parsed as application/json" }

          context "when the content type is also nil" do
            let(:content_type) { nil }

            its([:contracts, 0]) { is_expected.to include "contentType must be filled (at index 0)" }
          end
        end

        context "when the consumer name in the content does not match the consumerName in the contract params" do
          let(:contract_hash) { { "consumer" => { "name" => "WRONG" }, "provider" => { "name" => "Bar" }, "interactions" => [] } }

          its([:contracts, 0]) { is_expected.to include "consumer name in contract content ('WRONG') must match consumerName in contract params ('Foo') (at index 0)" }
        end

        context "when there is no consumer name in the content" do
          let(:contract_hash) { {  } }

          it { is_expected.to be_empty }
        end

        context "when the consumer name in the contract node does not match the pacticipant name" do
          let(:consumer_name) { "WRONG" }

          its([:contracts]) { is_expected.to include(match("consumerName ('WRONG') must match pacticipantName ('Foo') (at index 0)")) }
        end

        context "when the providerName in the contract node does not match the provider name in the contract content" do
          let(:contract_hash) { { "consumer" => { "name" => "Foo" }, "provider" => { "name" => "WRONG" }, "interactions" => [] } }

          its([:contracts, 0]) { is_expected.to include "provider name in contract content ('WRONG') must match providerName in contract params ('Bar') (at index 0)" }
        end

        context "when the providerName in the contract node is a space" do
          let(:provider_name) { " " }

          its([:contracts, 0]) { is_expected.to include "blank" }
        end

        context "when the contract has been successfully JSON parsed to an object that is not a hash" do
          let(:decoded_parsed_content) { "contract" }

          its([:contracts, 0]) { is_expected.to eq "parsed content was expected to be a Hash but was a String (at index 0)" }
        end

        context "when the consumer name is missing and there is a validation error with the content" do
          let(:params) do
            JSON.parse(File.read("spec/fixtures/invalid-publish-contract-body.json"), symbolize_names: true)
          end

          it "handles multiple errors" do
            expect(subject[:contracts]).to include "consumerName is missing (at index 0)"
            expect(subject[:contracts]).to include "providerName is missing (at index 0)"
            expect(subject[:contracts]).to include "contentType is missing (at index 0)"
            expect(subject[:contracts]).to include "specification is missing (at index 0)"
          end
        end

        context "when there is a non UTF-8 character in the base64 decoded contract" do
          let(:encoded_contract) { Base64.strict_encode64(decoded_content) }
          let(:decoded_content) { "{\"key\": \"ABCDEFG\x8FDEF\" }" }
          let(:decoded_parsed_content) { PactBroker::Pacts::Parse.call(decoded_content) }

          it "returns an error" do
            expect(subject[:contracts].first).to include "UTF-8 character at char 17"
          end
        end

        context "when the contracts array does not contain hashes" do
          let(:contracts) { ["string" ]}

          it { is_expected.to_not be_empty }
        end

        context "when the contracts is not an array" do
          let(:contracts) { "string" }

          it { is_expected.to_not be_empty }
        end
      end
    end
  end
end
