require "pact_broker/pacts/metadata"

module PactBroker
  module Pacts
    module Metadata
      describe "#build_metadata_for_pact_for_verification" do
        let(:selectors) do
          Selectors.new([ResolvedSelector.new({ latest: true, consumer: "consumer", tag: "tag" }, consumer_version)])
        end
        let(:consumer_version) { double("version", number: "2", id: 1) }
        let(:verifiable_pact) { double("PactBroker::Pacts::VerifiablePact", wip: wip, selectors: selectors, pending?: is_pending) }
        let(:is_pending) { nil }
        let(:wip) { false }

        subject { Metadata.build_metadata_for_pact_for_verification(verifiable_pact) }

        it "builds the metadata with the resolved selectors" do
          expect(subject).to eq({
            "s" => [
              {
                "l" => true,
                "t" => "tag",
                "cv" => 1
              }
            ]
          })
        end

        context "when wip is true" do
          let(:wip) { true }

          it { is_expected.to eq "w" => true }
        end

        context "when the pact is pending" do
          let(:is_pending) { true }

          it { is_expected.to include "p" => true }
        end

        context "when the selector was deployed" do
          let(:selectors) do
            Selectors.new([ResolvedSelector.new({ environment_name: "prod" }, consumer_version)])
          end

          its(["s"]) { is_expected.to include_hash_matching "e" => "prod" }
        end
      end

      describe "parse_metadata" do
        context "with a consumer version id" do
          before do
            allow(PactBroker::Domain::Version).to receive(:find).with(id: 1).and_return(consumer_version)
          end

          let(:consumer_version) { double("version", number: "2", id: 1) }

          # Not an actual possible selector, just avoiding writing more tests
          let(:incoming_metadata) do
            {
              "cv" => 1,
              "cvt" => ["tag"],
              "w" => true,
              "s" => [
                {
                  "l" => true,
                  "t" => "tag",
                  "cv" => 1,
                  "e" => "prod",
                  "b" => "main"
                }
              ],
              "p" => true
            }
          end

          let(:parsed_metadata) do
            {
              :consumer_version_number => "2",
              :consumer_version_tags => ["tag"],
              :wip => true,
              :pending => true,
              :consumer_version_selectors => [
                {
                  :latest => true,
                  :tag => "tag",
                  :consumer_version_number => "2",
                  :environment => "prod",
                  :branch => "main"
                }
              ]
            }
          end

          it "expands the key names" do
            expect(Metadata.parse_metadata(incoming_metadata)).to eq parsed_metadata
          end

          context "when the version can't be found" do
            let(:consumer_version) { nil }

            let(:parsed_metadata) do
              {
                :consumer_version_number => nil,
                :consumer_version_tags => ["tag"],
                :wip => true,
                :pending => true,
                :consumer_version_selectors => [
                  {
                    :latest => true,
                    :tag => "tag",
                    :consumer_version_number => nil,
                    :environment => "prod",
                    :branch => "main"
                  }
                ]
              }
            end

            it "sets the consumer version number to nil" do
              expect(Metadata.parse_metadata(incoming_metadata)).to eq parsed_metadata
            end
          end
        end

        context "with a consumer version number (support the old format for previously created URLs)" do
          let(:incoming_metadata) do
            {
              "cvn" => "2",
              "cvt" => ["tag"],
              "w" => true,
              "s" => [
                {
                  "l" => true,
                  "t" => "tag"
                }
              ]
            }
          end

          let(:parsed_metadata) do
            {
              :consumer_version_number => "2",
              :consumer_version_tags => ["tag"],
              :wip => true,
              :consumer_version_selectors => [
                {
                  :latest => true,
                  :tag => "tag"
                }
              ]
            }
          end

          it "expands the key names" do
            expect(Metadata.parse_metadata(incoming_metadata)).to eq parsed_metadata
          end
        end
      end
    end
  end
end
