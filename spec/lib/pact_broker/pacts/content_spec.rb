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

        context "when the interaction is a hash" do
          it "adds ids to the interactions" do
            expect(Content.from_hash(pact_hash).with_ids.interactions.first["id"]).to eq "some-id"
          end
        end

        context "when the interaction is not a hash" do
          let(:interaction) { 1 }

          it "does not add an id" do
            expect(Content.from_hash(pact_hash).with_ids.interactions.first).to eq interaction
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

          it "adds ids to the messages" do
            expect(Content.from_hash(pact_hash).with_ids.messages.first["id"]).to eq "some-id"
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
    end
  end
end
