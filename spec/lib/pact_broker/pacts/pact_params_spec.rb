require "spec_helper"
require "pact_broker/pacts/pact_params"

module PactBroker
  module Pacts
    describe PactParams do

      let(:body) { load_fixture("a_consumer-a_provider.json") }
      let(:consumer_version_number) { "1.2.3" }
      let(:headers) { { "X-Pact-Consumer-Version" => consumer_version_number, "Host" => "example.org" } }
      let(:revision_number) { "1" }
      let(:path_info) do
        {
          consumer_name: "Consumer",
          provider_name: "Provider",
          consumer_version_number: "1.2.3",
          revision_number: revision_number,
          pact_version_sha: "123"
        }
      end

      describe "from_path_info" do
        subject { PactParams.from_path_info(path_info) }

        it "extracts the consumer name from the path" do
          expect(subject.consumer_name).to eq "Consumer"
        end

        it "extracts the provider name from the path" do
          expect(subject.provider_name).to eq "Provider"
        end

        it "extracts the consumer_version_number from the path" do
          expect(subject.consumer_version_number).to eq "1.2.3"
        end

        it "extracts the revision_number from the path" do
          expect(subject.revision_number).to eq "1"
        end

        it "extracts the pact_version_sha from the path" do
          expect(subject.pact_version_sha).to eq "123"
        end
      end

      describe "from_request" do

        context "from a PUT request" do
          let(:request) { Webmachine::Request.new("PUT", "/", headers, body)}

          subject { PactParams.from_request(request, path_info) }

          it "extracts the consumer name from the path" do
            expect(subject.consumer_name).to eq "Consumer"
          end

          it "extracts the provider name from the path" do
            expect(subject.provider_name).to eq "Provider"
          end

          it "extracts the consumer_version_number from the path" do
            expect(subject.consumer_version_number).to eq "1.2.3"
          end

          it "extracts the revision_number from the path" do
            expect(subject.revision_number).to eq "1"
          end

          it "extracts the json_content" do
            expect(subject.json_content).to eq JSON.parse(body).to_json
          end

          it "removes whitespace from the json_content" do
            expect(subject.json_content).to_not include "\n"
          end

          it "extracts the consumer name from the pact" do
            expect(subject.consumer_name_in_pact).to eq "A Consumer"
          end

          it "extracts the provider name from the pact" do
            expect(subject.provider_name_in_pact).to eq "A Provider"
          end

          context "with no revision_number" do
            let(:revision_number) { nil }
            it "the revision_number is null" do
              expect(subject.revision_number).to be nil
            end
          end

          context "with missing data" do
            let(:body){ "" }

            it "the consumer name from the pact is nil" do
              expect(subject.consumer_name_in_pact).to be nil
            end

            it "the provider name from the pact is nil" do
              expect(subject.provider_name_in_pact).to be nil
            end

            it "extracts the json_content" do
              expect(subject.json_content).to eq ""
            end
          end
        end
      end
    end
  end
end
