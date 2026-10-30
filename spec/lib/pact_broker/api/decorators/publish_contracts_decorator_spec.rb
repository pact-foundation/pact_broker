require "pact_broker/api/decorators/publish_contracts_decorator"
require "pact_broker/contracts/contracts_to_publish"
require "pact_broker/pacts/generate_sha"

module PactBroker
  module Api
    module Decorators
      describe PublishContractsDecorator do
        describe "from_hash" do
          before do
            PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = true
          end

          let(:hash) do
            {
              "pacticipantName" => "Foo",
              "pacticipantVersionNumber" => "1",
              "contracts" => [
                {
                  "consumerName" => "Foo",
                  "providerName" => "Bar",
                  "specification" => "pact",
                  "contentType" => "application/json",
                  "decodedContent" => decoded_content,
                  "decodedParsedContent" => decoded_parsed_content
                }
              ]
            }
          end
          let(:decoded_content) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [{ description: "a" }] }.to_json }
          let(:decoded_parsed_content) { JSON.parse(decoded_content) }

          subject { PublishContractsDecorator.new(PactBroker::Contracts::ContractsToPublish.new).from_hash(hash, { user_options: { sha_generator: PactBroker::Pacts::GenerateSha } }) }

          it "sets the decoded content" do
            expect(subject.contracts.first.decoded_content).to eq decoded_content
          end

          it "sets the pact version sha generated from the content" do
            expect(subject.contracts.first.pact_version_sha).to eq PactBroker::Pacts::GenerateSha.call(decoded_content)
          end

          # This does not happen in a real request - it is used to show which content the sha is generated from
          context "when the parsed content is different from the decoded content" do
            let(:decoded_parsed_content) { JSON.parse(other_content) }
            let(:other_content) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [{ description: "b" }] }.to_json }

            it "generates the sha from the already parsed content, rather than parsing the decoded content again" do
              expect(subject.contracts.first.pact_version_sha).to eq PactBroker::Pacts::GenerateSha.call(other_content)
            end
          end

          context "when there is no parsed content" do
            let(:hash) { super().tap { |h| h["contracts"].first.delete("decodedParsedContent") } }

            it "generates the sha from the decoded content" do
              expect(subject.contracts.first.pact_version_sha).to eq PactBroker::Pacts::GenerateSha.call(decoded_content)
            end
          end
        end
      end
    end
  end
end
