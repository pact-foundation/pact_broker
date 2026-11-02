require "pact_broker/pacts/generate_sha"

module PactBroker
  module Pacts
    describe GenerateSha do
      describe ".call integration test" do
        let(:json_content) do
          {
            interactions: [{a: 1, b: 2}, {c: 3, d: 4}],
            metadata: {
              pactSpecification: {
                version: "1"
              }
            }
          }.to_json
        end

        let(:json_content_with_only_order_difference) do
          {
            interactions: [{d: 4, c: 3}, {b: 2, a: 1}],
            metadata: {
              :'pact-specification' => {
                version: "1"
              }
            }
          }.to_json
        end

        let(:json_content_with_diff_interactions) do
          {
            interactions: [{a: 9999, b: 2}, {c: 3, d: 4}],
            metadata: {
              pactSpecification: {
                version: "1"
              }
            }
          }.to_json
        end

        before do
          allow(Content).to receive(:from_json).and_return(content)
          allow(content).to receive(:sort).and_return(content)
        end

        let(:content) { instance_double("PactBroker::Pacts::Content", content_that_affects_verification_results: content_that_affects_verification_results) }
        let(:content_that_affects_verification_results) { double("content", to_json: "foo") }

        subject { GenerateSha.call(json_content) }

        it "accepts options in case there is any future requirement for a second argument" do
          expect{ GenerateSha.call(json_content, some: "options") }.to_not raise_error
        end

        context "when equality is based on the verifiable content only" do
          before do
            PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = true
          end

          it "sorts the content" do
            expect(content).to receive(:sort)
            subject
          end

          it "creates the sha from the sorted content JSON" do
            expect(Digest::SHA1).to receive(:hexdigest).with(content_that_affects_verification_results.to_json)
            subject
          end

          it "returns the sha" do
            expect(subject).to eq "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33"
          end
        end

        context "when equality is based on the verifiable content only" do
          it "does not sort the content" do
            expect(Content).to_not receive(:from_json)
            subject
          end

          it "creates the sha from the original JSON" do
            expect(Digest::SHA1).to receive(:hexdigest).with(json_content)
            subject
          end

          it "returns the sha" do
            expect(subject).to eq "ebc0feee91fb7fc0acf8420426184478ebaf648a"
          end
        end
      end

      describe ".call with the parsed content" do
        let(:json_content) do
          {
            interactions: [{d: 4, c: 3}, {b: 2, a: 1}],
            metadata: {
              pactSpecification: {
                version: "1"
              }
            }
          }.to_json
        end

        # Frozen, so that an error is raised if generating the sha modifies it
        let(:parsed_content) { JSON.parse(json_content, freeze: true) }

        subject { GenerateSha.call(json_content, parsed_content: parsed_content) }

        context "when equality is based on the verifiable content only" do
          before do
            PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = true
          end

          it "returns the same sha as when the JSON is parsed" do
            expect(subject).to eq GenerateSha.call(json_content)
          end

          it "does not modify the parsed content" do
            expect { subject }.to_not raise_error
          end

          # This is not a valid way to call it - it is used to show which content the sha is generated from
          context "when the parsed content is different from the JSON" do
            let(:parsed_content) { JSON.parse(other_json_content) }
            let(:other_json_content) do
              {
                interactions: [{a: 9999, b: 2}],
                metadata: {
                  pactSpecification: {
                    version: "1"
                  }
                }
              }.to_json
            end

            it "generates the sha from the parsed content, rather than parsing the JSON again" do
              expect(subject).to eq GenerateSha.call(other_json_content)
            end
          end

          context "when the parsed content is not a Hash" do
            let(:parsed_content) { nil }

            it "generates the sha from the JSON" do
              expect(subject).to eq GenerateSha.call(json_content)
            end
          end
        end

        context "when equality is based on the full content" do
          it "generates the sha from the original JSON, ignoring the parsed content" do
            expect(subject).to eq Digest::SHA1.hexdigest(json_content)
          end
        end
      end
    end
  end
end
