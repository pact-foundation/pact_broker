require 'pact_broker/metrics/service'

module PactBroker
  module Metrics
    module Service
      describe "#metrics" do
        subject { Service.metrics }

        describe "verificationResultsPerPactVersion" do
          before do
            td.create_pact_with_hierarchy
              .create_consumer_version_tag("prod")
              .comment("this pact version will have 2 verifications")
              .create_verification
              .create_verification(number: 2, tag_names: ["main"])
              .revise_pact
              .comment("this pact version will have 1 verification")
              .create_verification
              .create_consumer_version
              .create_consumer_version_tag("main")
              .create_pact
              .comment("this pact will have 1 verification")
              .create_verification
              .create_consumer_version
              .create_consumer_version_tag("main")
              .create_pact
              .comment("this pact will have 1 verification")
              .create_verification
          end

          let(:distribution) { subject[:verificationResultsPerPactVersion][:distribution] }

          it "returns a distribution of verifications per pact version" do
            expect(distribution).to eq(1 => 3, 2 => 1)
          end
        end

        describe "pactRevisionsPerPactPublication" do
          before do
            td.create_pact_with_hierarchy
              .comment("this consumer version will have 3 revisions")
              .revise_pact
              .revise_pact
              .create_consumer_version
              .create_pact
              .comment("this consumer version will have 1 revision")
              .revise_pact
          end

          let(:distribution) { subject[:pactRevisionsPerConsumerVersion][:distribution] }

          it "returns a distribution of pact revisions per consumer version" do
            expect(distribution).to eq(2 => 1, 3 => 1)
          end
        end
      end
    end
  end
end
