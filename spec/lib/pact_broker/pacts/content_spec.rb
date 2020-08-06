require 'pact_broker/pacts/content'

module PactBroker
  module Pacts
    describe Content do
      describe "with_ids" do
        let(:pact_hash) do
          {
            'ignored' => 'foo',
            'interactions' => [interaction],
            'metadata' => {
              'foo' => 'bar'
            }
          }
        end
        let(:interaction) { { "foo" => "bar" } }

        before do
          allow(GenerateInteractionSha).to receive(:call).and_return("some-id")
        end

        subject { Content.from_hash(pact_hash).with_ids }

        context "when the interaction has an existing _id" do
          let(:interaction) { { "_id" => "blah", "foo" => "bar" } }

          it "removes the i_d before creating the sha" do
            expect(GenerateInteractionSha).to receive(:call).with("foo" => "bar")
            subject
          end
        end

        context "when the interaction is a hash" do
          it "adds an _id to each interaction" do
            expect(subject.interactions.first["_id"]).to eq "some-id"
          end
        end

        context "when the interaction is not a hash" do
          let(:interaction) { 1 }

          it "does not add an _id" do
            expect(subject.interactions.first).to eq interaction
          end
        end

        context "when the pact is a message pact" do
          let(:pact_hash) do
            {
              'ignored' => 'foo',
              'messages' => [interaction],
              'metadata' => {
                'foo' => 'bar'
              }
            }
          end

          it "adds an _id to each message" do
            expect(subject.messages.first["_id"]).to eq "some-id"
          end
        end

        context "when override_existing_ids = false (for setting up test data)" do
          let(:interaction) { { "_id" => "1", "foo" => "bar" } }

          it "does not override the existing ids" do
            expect(subject.interactions.first["_id"]).to eq "1"
          end
        end
      end

      describe "content_that_affects_verification_results" do

        subject { Content.from_hash(pact_hash).content_that_affects_verification_results }

        context "with messages" do
          let(:pact_hash) do
            {
              'ignored' => 'foo',
              'messages' => [1],
              'metadata' => {
                'pactSpecification' => {
                  'version' => '1'
                }
              }
            }
          end

          let(:expected_content) do
            {
              'messages' => [1],
              'pact_specification_version' => '1'
            }
          end

          it "extracts the messages and pact_specification_version" do
            expect(subject).to eq expected_content
          end
        end

        context "with interactions" do
          let(:pact_hash) do
            {
              'ignored' => 'foo',
              'interactions' => [1],
              'metadata' => {
                'pactSpecification' => {
                  'version' => '1'
                }
              }
            }
          end

          let(:expected_content) do
            {
              'interactions' => [1],
              'pact_specification_version' => '1'
            }
          end

          it "extracts the interactions and pact_specification_version" do
            expect(subject).to eq expected_content
          end
        end

        context "with both messages and interactions, even though this should never happen" do
          let(:pact_hash) do
            {
              'ignored' => 'foo',
              'interactions' => [1],
              'messages' => [2],
              'metadata' => {
                'pactSpecification' => {
                  'version' => '1'
                }
              }
            }
          end

          let(:expected_content) do
            {
              'interactions' => [1],
              'messages' => [2],
              'pact_specification_version' => '1'
            }
          end

          it "extracts the interactions and pact_specification_version" do
            expect(subject).to eq expected_content
          end
        end

        context "with neither messages nor interactions" do
          let(:pact_hash) do
            {
              'ignored' => 'foo',
              'foo' => [1],
              'metadata' => {
                'pactSpecification' => {
                  'version' => '1'
                }
              }
            }
          end

          it "returns the entire hash" do
            expect(subject).to eq pact_hash
          end
        end

        context "when somebody publishes an array as the top level element" do
          let(:pact_hash) do
            [{ "foo" => "bar" }]
          end

          it "returns the entire document" do
            expect(subject).to eq pact_hash
          end
        end
      end

      describe "#pact_specification_version" do
        subject { Content.from_hash(json) }
        context 'with pactSpecification.version' do
          let(:json) do
            {
              'metadata' => {
                'pactSpecification' => {
                  'version' => '1'
                }
              }
            }
          end

          its(:pact_specification_version) { is_expected.to eq '1' }
        end

        context 'with pact-specification.version' do
          let(:json) do
            {
              'metadata' => {
                'pact-specification' => {
                  'version' => '1'
                }
              }
            }
          end

          its(:pact_specification_version) { is_expected.to eq '1' }
        end

        context 'with pactSpecificationVersion' do
          let(:json) do
            {
              'metadata' => {
                'pactSpecificationVersion' => '1'
              }
            }
          end

          its(:pact_specification_version) { is_expected.to eq '1' }
        end

        context 'with an array for content' do
          let(:json) { [] }

          its(:pact_specification_version) { is_expected.to eq nil }
        end
      end

      describe "with_test_results" do
        let(:test_results) do
          {
            "tests" => [
              {
                "interactionProviderState" => "ps1",
                "interactionDescription" => "desc1"
              },{
                "interactionProviderState" => "ps1",
                "interactionDescription" => "desc1"
              }
            ]
          }
        end

        let(:pact_content) do
          {
            "interactions" => [
              {
               "providerState" => "ps1",
               "description" => "desc1",
              },
              {
               "providerState" => "ps2",
               "description" => "desc2",
              }
            ]
          }
        end

        subject { Content.from_hash(pact_content).with_test_results(test_results) }

        let(:merged) do
          {
            "interactions" => [
              {
               "providerState" => "ps1",
               "description" => "desc1",
               "tests" => [
                {
                  "interactionProviderState" => "ps1",
                  "interactionDescription" => "desc1",
                },{
                  "interactionProviderState" => "ps1",
                  "interactionDescription" => "desc1",
                }
               ]
              },{
               "providerState" => "ps2",
               "description" => "desc2",
               "tests" => []
              }
            ]
          }
        end

        let(:merged_with_empty_tests) do
          {
            "interactions" => [
              {
               "providerState" => "ps1",
               "description" => "desc1",
               "tests" => []
              },{
               "providerState" => "ps2",
               "description" => "desc2",
               "tests" => []
              }
            ]
          }
        end

        it "merges the contents with the results" do
          expect(subject.to_hash).to eq merged
        end

        it "returns interactions without test results" do
          expect(subject.interactions_missing_test_results.count).to eq 1
        end

        context "with no interactions" do
          let(:pact_content) { {} }

          it "does not blow up" do
            expect(subject.interactions_missing_test_results.count).to eq 0
          end
        end

        context "with nil test results" do
          let(:test_results) { nil }

          it "does not blow up" do
            expect(subject.to_hash).to eq merged_with_empty_tests
          end

          it "returns interactions without test results" do
            expect(subject.interactions_missing_test_results.count).to eq 2
          end
        end

        context "with nil tests" do
          let(:test_results) { {} }

          it "does not blow up" do
            expect(subject.to_hash).to eq merged_with_empty_tests
          end
        end

        context "with empty tests" do
          let(:test_results) { { "tests" => [] } }

          it "does not blow up" do
            expect(subject.to_hash).to eq merged_with_empty_tests
          end
        end

        context "with tests not an array" do
          let(:test_results) { { "tests" => {} } }

          it "does not blow up" do
            expect(subject.to_hash).to eq merged_with_empty_tests
          end
        end

        context "with tests an array of not hashes" do
          let(:test_results) { { "tests" => [1] } }

          it "does not blow up" do
            expect(subject.to_hash).to eq merged_with_empty_tests
          end
        end
      end
    end
  end
end
