require 'pact_broker/pacts/merge_verification_results'

module PactBroker
  module Pacts
    module MergeVerificationResults
      describe ".call" do
        let(:interactions) do
            [{
              "_id" => "1",
              "request" => "make me a sandwich"
            }]
        end

        let(:test_results) do
          [{
            "interactionId" => "1",
            "some" => "results"
            }
          ]
        end

        subject { MergeVerificationResults.call(interactions, test_results)}

        it "" do
          expect(subject).to eq [{"_id" => "1", "request" => "make me a sandwich", "some" => "results"}]
        end

        context "when the _id is missing" do
          let(:interactions) do
              [{
                "request" => "make me a sandwich"
              }]
          end

          it "does not change the interaction" do
            expect(subject).to eq interactions
          end
        end

        context "when the test results isn't an array" do
          let(:test_results) do
            {}
          end

          it "does not blow up" do
            expect(subject).to eq interactions
          end
        end

        context "when the test results is nil" do
          let(:test_results) { nil }

          it "does not blow up" do
            expect(subject).to eq interactions
          end
        end

        context "when the test results is true" do
          let(:test_results) { true }

          it "does not blow up" do
            expect(subject).to eq interactions
          end
        end

      end
    end
  end
end
